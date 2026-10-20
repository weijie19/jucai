import 'package:flutter/material.dart';
import '../data/account_repository.dart';
import '../data/category_repository.dart';
import '../data/debt_repository.dart';
import '../data/transaction_repository.dart';
import '../data/transfer_repository.dart';
import '../models/account.dart';
import '../models/debt.dart';
import '../models/models.dart';
import '../services/amount.dart';
import '../widgets/category_icons.dart';
import 'add_transaction_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

/// 账户明细里的一条统一记录：流水 / 转账 / 借贷 / 还款。
class _LedgerEntry {
  final String date;
  final String? time;
  final String label;
  final String? note;
  final int amountCents; // 正=流入，负=流出
  final IconData icon;
  final int color;
  final Transaction? transaction; // 仅「流水」可编辑/删除
  const _LedgerEntry({
    required this.date,
    this.time,
    required this.label,
    this.note,
    required this.amountCents,
    required this.icon,
    required this.color,
    this.transaction,
  });
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final _txRepo = TransactionRepository();
  final _accountRepo = AccountRepository();
  final _catRepo = CategoryRepository();
  final _transferRepo = TransferRepository();
  final _debtRepo = DebtRepository();

  List<_LedgerEntry> _entries = [];
  int _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final accountId = widget.account.id!;
    final txs = await _txRepo.getByAccount(accountId);
    final transfers = await _transferRepo.getByAccount(accountId);
    final debts = await _debtRepo.getByAccount(accountId);
    final repayments = await _debtRepo.getRepaymentsByAccount(accountId);
    final allDebts = await _debtRepo.getAll();
    final cats = await _catRepo.getAll();
    final accounts = await _accountRepo.getAll();
    final balance = await _accountRepo.balance(accountId);

    final catById = {for (final c in cats) c.id: c};
    final accountName = {for (final a in accounts) a.id: a.name};
    final debtById = {for (final d in allDebts) d.id!: d};

    final entries = <_LedgerEntry>[];

    for (final t in txs) {
      final cat = catById[t.categoryId];
      entries.add(_LedgerEntry(
        date: t.date,
        time: t.time,
        label: cat?.name ?? '未分类',
        note: t.note,
        amountCents: t.type == TxType.income ? t.amountCents : -t.amountCents,
        icon: iconFor(cat?.icon ?? 'more_horiz'),
        color: cat?.color ?? 0xFF90A4AE,
        transaction: t,
      ));
    }

    for (final tr in transfers) {
      final isOut = tr.fromAccountId == accountId;
      entries.add(_LedgerEntry(
        date: tr.date,
        label: isOut
            ? '转出到「${accountName[tr.toAccountId] ?? '账户'}」'
            : '从「${accountName[tr.fromAccountId] ?? '账户'}」转入',
        note: tr.note,
        amountCents: isOut ? -(tr.amountCents + tr.feeCents) : tr.amountCents,
        icon: Icons.swap_horiz,
        color: 0xFF42A5F5,
      ));
    }

    for (final d in debts) {
      final isBorrow = d.direction == DebtDirection.borrow;
      entries.add(_LedgerEntry(
        date: d.date,
        label: isBorrow ? '借入「${d.counterparty}」' : '借出给「${d.counterparty}」',
        note: d.note,
        amountCents: isBorrow ? d.totalCents : -d.totalCents,
        icon: Icons.handshake_outlined,
        color: isBorrow ? 0xFF66BB6A : 0xFFEF5350,
      ));
    }

    for (final r in repayments) {
      final debt = debtById[r.debtId];
      final isLend = debt?.direction == DebtDirection.lend; // 借出，现在收回
      final counterparty = debt?.counterparty ?? '';
      entries.add(_LedgerEntry(
        date: r.date,
        label: isLend ? '收回「$counterparty」还款' : '归还「$counterparty」欠款',
        note: r.note,
        amountCents: isLend ? r.amountCents : -r.amountCents,
        icon: Icons.handshake_outlined,
        color: isLend ? 0xFF66BB6A : 0xFFEF5350,
      ));
    }

    entries.sort((a, b) {
      final dc = b.date.compareTo(a.date);
      if (dc != 0) return dc;
      return (b.time ?? '').compareTo(a.time ?? '');
    });

    if (!mounted) return;
    setState(() {
      _entries = entries;
      _balance = balance;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<_LedgerEntry>>{};
    for (final e in _entries) {
      groups.putIfAbsent(e.date, () => []).add(e);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text(widget.account.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('该账户暂无记录'))
                      : ListView.builder(
                          itemCount: dates.length,
                          itemBuilder: (context, i) {
                            final date = dates[i];
                            return _buildDayGroup(date, groups[date]!);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('当前余额'),
              Text('¥${formatCents(_balance)}', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayGroup(String date, List<_LedgerEntry> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(date, style: Theme.of(context).textTheme.labelLarge),
        ),
        ...list.map((e) {
          final amountText = e.amountCents > 0
              ? '+${formatCents(e.amountCents)}'
              : formatCents(e.amountCents);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(e.color),
              child: Icon(e.icon, color: Colors.white, size: 20),
            ),
            title: Text(e.label),
            subtitle: Text([e.time, e.note].where((s) => s != null && s.isNotEmpty).join(' · ')),
            trailing: Text(
              amountText,
              style: TextStyle(
                color: e.amountCents > 0 ? Colors.green : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: e.transaction == null
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddTransactionScreen(transaction: e.transaction!)),
                    );
                    _reload();
                  },
            onLongPress: e.transaction == null ? null : () => _confirmDelete(e.transaction!),
          );
        }),
      ],
    );
  }

  Future<void> _confirmDelete(Transaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条记录？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await _txRepo.delete(t.id!);
      _reload();
    }
  }
}
