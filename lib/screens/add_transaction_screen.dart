import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/account_repository.dart';
import '../data/category_repository.dart';
import '../data/debt_repository.dart';
import '../data/tag_repository.dart';
import '../data/transaction_repository.dart';
import '../data/transfer_repository.dart';
import '../models/account.dart';
import '../models/debt.dart';
import '../models/models.dart';
import '../models/tag.dart';
import '../models/transfer.dart';
import '../services/amount.dart';
import '../widgets/category_icons.dart';
import '../widgets/wheel_date_picker.dart';

enum _EntryMode { expense, income, transfer, debt }

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _catRepo = CategoryRepository();
  final _txRepo = TransactionRepository();
  final _accountRepo = AccountRepository();
  final _tagRepo = TagRepository();
  final _transferRepo = TransferRepository();
  final _debtRepo = DebtRepository();

  _EntryMode _mode = _EntryMode.expense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _feeController = TextEditingController();
  final _counterpartyController = TextEditingController();
  DateTime _date = DateTime.now();
  List<Category> _categories = [];
  List<Account> _accounts = [];
  List<Tag> _tags = [];
  List<int> _selectedTagIds = [];
  int? _categoryId;
  int? _accountId;
  int? _fromId;
  int? _toId;
  DebtDirection _debtDirection = DebtDirection.lend;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _mode = t.type == TxType.income ? _EntryMode.income : _EntryMode.expense;
      _amountController.text = formatCents(t.amountCents);
      _noteController.text = t.note ?? '';
      final d = DateTime.parse(t.date);
      _date = t.time == null
          ? d
          : DateTime(d.year, d.month, d.day, int.parse(t.time!.substring(0, 2)), int.parse(t.time!.substring(3, 5)));
      _categoryId = t.categoryId;
      _accountId = t.accountId;
    }
    _load();
  }

  bool get _isTxMode => _mode == _EntryMode.expense || _mode == _EntryMode.income;

  TxType get _txType => _mode == _EntryMode.income ? TxType.income : TxType.expense;

  Future<void> _load() async {
    final accounts = await _accountRepo.getAll();
    final tags = await _tagRepo.getAll();
    final selectedTagIds = <int>[];
    if (widget.transaction != null) {
      final existing = await _tagRepo.tagsForTransaction(widget.transaction!.id!);
      selectedTagIds.addAll(existing.map((t) => t.id!));
    }
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _tags = tags;
      _selectedTagIds = selectedTagIds;
      _accountId ??= accounts.isNotEmpty ? accounts.first.id : null;
      if (accounts.length >= 2) {
        _fromId ??= accounts[0].id;
        _toId ??= accounts[1].id;
      }
      _loading = false;
    });
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _catRepo.getByType(_txType);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (_categoryId == null && cats.isNotEmpty) _categoryId = cats.first.id;
    });
  }

  Future<void> _save({bool keepAdding = false}) async {
    if (_mode == _EntryMode.transfer) {
      await _saveTransfer();
      return;
    }
    if (_mode == _EntryMode.debt) {
      await _saveDebt();
      return;
    }
    final cents = parseAmountToCents(_amountController.text);
    if (cents == null || cents == 0) {
      _toast('请输入有效金额');
      return;
    }
    if (_categoryId == null) {
      _toast('请选择分类');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final date = DateFormat('yyyy-MM-dd').format(_date);
    final t = Transaction(
      id: widget.transaction?.id,
      type: _txType,
      amountCents: cents.abs(),
      categoryId: _categoryId!,
      accountId: _accountId,
      date: date,
      time: DateFormat('HH:mm').format(_date),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      createdAt: widget.transaction?.createdAt ?? now,
      updatedAt: now,
    );
    if (widget.transaction == null) {
      final saved = await _txRepo.insert(t);
      await _tagRepo.setTagsForTransaction(saved.id!, _selectedTagIds);
    } else {
      await _txRepo.update(t);
      await _tagRepo.setTagsForTransaction(widget.transaction!.id!, _selectedTagIds);
    }
    if (!mounted) return;
    if (keepAdding) {
      setState(() {
        _amountController.clear();
        _noteController.clear();
      });
      _toast('已保存，继续记下一笔');
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _saveTransfer() async {
    if (_fromId == null || _toId == null) {
      _toast('请先创建至少两个账户');
      return;
    }
    if (_fromId == _toId) {
      _toast('转出和转入账户不能相同');
      return;
    }
    final cents = parseAmountToCents(_amountController.text);
    if (cents == null || cents <= 0) {
      _toast('请输入有效金额');
      return;
    }
    final fee = parseAmountToCents(_feeController.text) ?? 0;
    final t = Transfer(
      fromAccountId: _fromId!,
      toAccountId: _toId!,
      amountCents: cents,
      feeCents: fee,
      date: DateFormat('yyyy-MM-dd').format(_date),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    await _transferRepo.insert(t);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _saveDebt() async {
    final name = _counterpartyController.text.trim();
    if (name.isEmpty) {
      _toast('请输入对方');
      return;
    }
    final cents = parseAmountToCents(_amountController.text);
    if (cents == null || cents <= 0) {
      _toast('请输入有效金额');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final d = Debt(
      direction: _debtDirection,
      counterparty: name,
      totalCents: cents,
      accountId: _accountId,
      date: DateFormat('yyyy-MM-dd').format(_date),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      status: DebtStatus.open,
      createdAt: now,
      updatedAt: now,
    );
    await _debtRepo.insert(d);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _feeController.dispose();
    _counterpartyController.dispose();
    super.dispose();
  }

  String _accountName(int? id) {
    for (final a in _accounts) {
      if (a.id == id) return a.name;
    }
    return _accounts.isNotEmpty ? _accounts.first.name : '账户';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.transaction == null ? '记一笔' : '编辑记录')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildAmountField(),
                _buildModeSwitcher(),
                Expanded(child: _buildModeContent()),
                _buildFields(),
                _buildNoteField(),
                _buildActions(),
              ],
            ),
    );
  }

  Widget _buildAmountField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _amountController,
        autofocus: true,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          prefixText: '¥ ',
          hintText: '0.00',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    final editing = widget.transaction != null;
    final segments = editing
        ? <ButtonSegment<_EntryMode>>[
            const ButtonSegment(value: _EntryMode.expense, label: Text('支出')),
            const ButtonSegment(value: _EntryMode.income, label: Text('收入')),
          ]
        : <ButtonSegment<_EntryMode>>[
            const ButtonSegment(value: _EntryMode.expense, label: Text('支出')),
            const ButtonSegment(value: _EntryMode.income, label: Text('收入')),
            const ButtonSegment(value: _EntryMode.transfer, label: Text('转账')),
            const ButtonSegment(value: _EntryMode.debt, label: Text('借贷')),
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SegmentedButton<_EntryMode>(
        segments: segments,
        selected: {_mode},
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        onSelectionChanged: (s) {
          final newMode = s.first;
          setState(() {
            _mode = newMode;
            if (_isTxMode) _categoryId = null;
          });
          if (_isTxMode) _loadCategories();
        },
      ),
    );
  }

  Widget _buildModeContent() {
    if (_isTxMode) {
      return Column(
        children: [
          _buildSelectedCategory(),
          Expanded(child: _buildCategoryGrid()),
        ],
      );
    }
    if (_mode == _EntryMode.transfer) return _buildTransferForm();
    return _buildDebtForm();
  }

  String _selectedCategoryName() {
    for (final c in _categories) {
      if (c.id == _categoryId) return c.name;
    }
    return _categories.isNotEmpty ? _categories.first.name : '';
  }

  Widget _buildSelectedCategory() {
    final name = _selectedCategoryName();
    if (name.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(name, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildCategoryGrid() {
    if (_categories.isEmpty) {
      return const Center(child: Text('暂无分类，请先在「我的-分类管理」中添加'));
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final c = _categories[i];
        final selected = c.id == _categoryId;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _categoryId = c.id),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: selected ? Color(c.color) : Color(c.color).withValues(alpha: 0.16),
                child: Icon(iconFor(c.icon), color: selected ? Colors.white : Color(c.color), size: 25),
              ),
              const SizedBox(height: 6),
              Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Theme.of(context).colorScheme.primary : null,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransferForm() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _accountSelectTile('转出账户', Icons.arrow_upward, _fromId, (id) => setState(() => _fromId = id)),
        const SizedBox(height: 8),
        _accountSelectTile('转入账户', Icons.arrow_downward, _toId, (id) => setState(() => _toId = id)),
        const SizedBox(height: 8),
        TextField(
          controller: _feeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '手续费（可选）',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtForm() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        SegmentedButton<DebtDirection>(
          segments: const [
            ButtonSegment(value: DebtDirection.lend, label: Text('我借出')),
            ButtonSegment(value: DebtDirection.borrow, label: Text('我借入')),
          ],
          selected: {_debtDirection},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _debtDirection = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _counterpartyController,
          decoration: const InputDecoration(
            labelText: '对方',
            hintText: '借给谁 / 向谁借',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _accountSelectTile('账户', Icons.account_balance_wallet_outlined, _accountId, (id) => setState(() => _accountId = id)),
      ],
    );
  }

  Widget _accountSelectTile(String label, IconData icon, int? selectedId, ValueChanged<int?> onChanged) {
    return InkWell(
      onTap: () => _pickAccountFor(onChanged, selectedId),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Text(_accountName(selectedId), style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Future<void> _pickAccountFor(ValueChanged<int?> onChanged, int? current) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择账户', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ..._accounts.map((a) => ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(a.color),
                    child: Icon(iconFor(a.icon), color: Colors.white, size: 16),
                  ),
                  title: Text(a.name),
                  trailing: a.id == current ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () => Navigator.pop(context, a.id),
                )),
          ],
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }

  Widget _buildFields() {
    final children = <Widget>[];
    if (_isTxMode || _mode == _EntryMode.debt) {
      children.add(Expanded(child: _fieldChip(Icons.account_balance_wallet_outlined, _accountName(_accountId), () => _pickAccountFor((id) => setState(() => _accountId = id), _accountId))));
    }
    children.add(Expanded(child: _fieldChip(Icons.event_outlined, DateFormat('MM-dd HH:mm').format(_date), _pickDate)));
    if (_isTxMode && _tags.isNotEmpty) {
      children.add(Expanded(
        child: _fieldChip(
          Icons.sell_outlined,
          _selectedTagIds.isEmpty ? '标签' : '${_selectedTagIds.length}个标签',
          _pickTags,
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(children: children),
    );
  }

  Widget _fieldChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: TextField(
        controller: _noteController,
        minLines: 8,
        maxLines: 8,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: '备注（可选）',
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final editing = widget.transaction != null;
    final confirmLabel = _mode == _EntryMode.transfer
        ? '确认转账'
        : _mode == _EntryMode.debt
            ? '保存'
            : '保存';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          if (!editing && _isTxMode) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _save(keepAdding: true),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('再记')),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: () => _save(),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(confirmLabel)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showWheelDatePicker(context, initialDate: _date, withTime: true);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTags() async {
    final selected = await showModalBottomSheet<List<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final current = List<int>.from(_selectedTagIds);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择标签', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      final on = current.contains(tag.id);
                      return FilterChip(
                        label: Text(tag.name),
                        selected: on,
                        onSelected: (v) {
                          setSheetState(() {
                            if (v) {
                              current.add(tag.id!);
                            } else {
                              current.remove(tag.id!);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, current),
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selected != null) setState(() => _selectedTagIds = selected);
  }
}
