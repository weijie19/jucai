import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/account_repository.dart';
import '../data/debt_repository.dart';
import '../models/account.dart';
import '../models/debt.dart';
import '../models/debt_repayment.dart';
import '../services/amount.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  final _repo = DebtRepository();
  final _accountRepo = AccountRepository();
  List<Debt> _debts = [];
  List<Account> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final debts = await _repo.getAll();
    final accounts = await _accountRepo.getAll();
    if (!mounted) return;
    setState(() {
      _debts = debts;
      _accounts = accounts;
      _loading = false;
    });
  }

  String _accountName(int? id) {
    if (id == null) return '';
    for (final a in _accounts) {
      if (a.id == id) return a.name;
    }
    return '';
  }

  Future<void> _edit([Debt? existing]) async {
    final result = await showDialog<Debt>(
      context: context,
      builder: (_) => _DebtDialog(debt: existing, accounts: _accounts),
    );
    if (result == null) return;
    if (existing == null) {
      await _repo.insert(result);
    } else {
      await _repo.update(result);
    }
    _reload();
  }

  Future<void> _repay(Debt debt) async {
    final result = await showDialog<DebtRepayment>(
      context: context,
      builder: (_) => _RepayDialog(debt: debt, accounts: _accounts),
    );
    if (result == null) return;
    await _repo.repay(debt, result);
    _reload();
  }

  Future<void> _confirmDelete(Debt d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除与「${d.counterparty}」的借贷？'),
        content: const Text('关联的还款记录会一并删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.delete(d.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lends = _debts.where((d) => d.direction == DebtDirection.lend).toList();
    final borrows = _debts.where((d) => d.direction == DebtDirection.borrow).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('借贷')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _section('我借出的', lends),
                _section('我借入的', borrows),
                if (_debts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('还没有借贷记录，点右下角 + 记一笔')),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _section(String title, List<Debt> debts) {
    if (debts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.labelLarge),
        ),
        ...debts.map((d) => _debtTile(d)),
      ],
    );
  }

  Widget _debtTile(Debt d) {
    final isLend = d.direction == DebtDirection.lend;
    final remaining = d.remainingCents ?? d.totalCents;
    final cleared = d.status == DebtStatus.cleared;
    final color = isLend ? const Color(0xFFEF5350) : const Color(0xFF66BB6A);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(isLend ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white, size: 20),
        ),
        title: Text(d.counterparty),
        subtitle: Text(
          '${cleared ? '已还清' : '剩余 ¥${formatCents(remaining)}'} · 共 ¥${formatCents(d.totalCents)}'
          '${_accountName(d.accountId).isEmpty ? '' : ' · ${_accountName(d.accountId)}'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!cleared)
              IconButton(
                icon: const Icon(Icons.payments_outlined),
                onPressed: () => _repay(d),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(d),
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => DebtDetailScreen(debt: d)));
          _reload();
        },
      ),
    );
  }
}

class DebtDetailScreen extends StatefulWidget {
  final Debt debt;
  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  final _repo = DebtRepository();
  List<DebtRepayment> _repayments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await _repo.getRepayments(widget.debt.id!);
    if (!mounted) return;
    setState(() {
      _repayments = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.debt;
    final remaining = d.remainingCents ?? d.totalCents;
    return Scaffold(
      appBar: AppBar(title: Text(d.counterparty)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(d.direction == DebtDirection.lend ? '借出' : '借入'),
                    subtitle: Text('共 ¥${formatCents(d.totalCents)} · 剩余 ¥${formatCents(remaining)}'),
                    trailing: Text(
                      d.status == DebtStatus.cleared ? '已还清' : '未还清',
                      style: TextStyle(
                        color: d.status == DebtStatus.cleared ? Colors.grey : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('还款记录', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_repayments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('还没有还款记录')),
                  )
                else
                  ..._repayments.map((r) => ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text('¥${formatCents(r.amountCents)}'),
                        subtitle: Text(r.date),
                      )),
              ],
            ),
    );
  }
}

class _DebtDialog extends StatefulWidget {
  final Debt? debt;
  final List<Account> accounts;
  const _DebtDialog({this.debt, required this.accounts});

  @override
  State<_DebtDialog> createState() => _DebtDialogState();
}

class _DebtDialogState extends State<_DebtDialog> {
  late DebtDirection _direction;
  late final TextEditingController _counterparty;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  int? _accountId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _direction = d?.direction ?? DebtDirection.lend;
    _counterparty = TextEditingController(text: d?.counterparty ?? '');
    _amount = TextEditingController(text: d == null ? '' : formatCents(d.totalCents));
    _note = TextEditingController(text: d?.note ?? '');
    _accountId = d?.accountId;
    if (d != null) _date = DateTime.parse(d.date);
  }

  @override
  void dispose() {
    _counterparty.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.debt == null ? '记一笔借贷' : '编辑借贷'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<DebtDirection>(
              segments: const [
                ButtonSegment(value: DebtDirection.lend, label: Text('借出')),
                ButtonSegment(value: DebtDirection.borrow, label: Text('借入')),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _counterparty,
              decoration: const InputDecoration(labelText: '对方'),
            ),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: '¥ ', labelText: '金额'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: '账户（可选）'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('不指定账户')),
                ...widget.accounts.map((a) => DropdownMenuItem<int?>(value: a.id, child: Text(a.name))),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(DateFormat('yyyy-MM-dd').format(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final name = _counterparty.text.trim();
            if (name.isEmpty) return;
            final cents = parseAmountToCents(_amount.text);
            if (cents == null || cents <= 0) return;
            final now = DateTime.now().millisecondsSinceEpoch;
            Navigator.pop(
              context,
              Debt(
                id: widget.debt?.id,
                direction: _direction,
                counterparty: name,
                totalCents: cents,
                remainingCents: widget.debt?.remainingCents,
                accountId: _accountId,
                date: DateFormat('yyyy-MM-dd').format(_date),
                note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                status: widget.debt?.status ?? DebtStatus.open,
                createdAt: widget.debt?.createdAt ?? now,
                updatedAt: now,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _RepayDialog extends StatefulWidget {
  final Debt debt;
  final List<Account> accounts;
  const _RepayDialog({required this.debt, required this.accounts});

  @override
  State<_RepayDialog> createState() => _RepayDialogState();
}

class _RepayDialogState extends State<_RepayDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  int? _accountId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _note = TextEditingController();
    _accountId = widget.debt.accountId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.debt.remainingCents ?? widget.debt.totalCents;
    return AlertDialog(
      title: Text('还款给「${widget.debt.counterparty}」'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('剩余未还 ¥${formatCents(remaining)}', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: '¥ ', labelText: '还款金额'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: '账户（可选）'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('不指定账户')),
                ...widget.accounts.map((a) => DropdownMenuItem<int?>(value: a.id, child: Text(a.name))),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(DateFormat('yyyy-MM-dd').format(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final cents = parseAmountToCents(_amount.text);
            if (cents == null || cents <= 0) return;
            Navigator.pop(
              context,
              DebtRepayment(
                debtId: widget.debt.id!,
                amountCents: cents,
                accountId: _accountId,
                date: DateFormat('yyyy-MM-dd').format(_date),
                note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
          },
          child: const Text('确认还款'),
        ),
      ],
    );
  }
}
