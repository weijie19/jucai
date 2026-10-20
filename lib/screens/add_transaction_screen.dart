import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/account_repository.dart';
import '../data/category_repository.dart';
import '../data/tag_repository.dart';
import '../data/transaction_repository.dart';
import '../models/account.dart';
import '../models/models.dart';
import '../models/tag.dart';
import '../services/amount.dart';
import '../widgets/category_icons.dart';
import '../widgets/wheel_date_picker.dart';

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

  TxType _type = TxType.expense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  List<Category> _categories = [];
  List<Account> _accounts = [];
  List<Tag> _tags = [];
  List<int> _selectedTagIds = [];
  int? _categoryId;
  int? _accountId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _type = t.type;
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

  Future<void> _load() async {
    final cats = await _catRepo.getByType(_type);
    final accounts = await _accountRepo.getAll();
    final tags = await _tagRepo.getAll();
    final selectedTagIds = <int>[];
    if (widget.transaction != null) {
      final existing = await _tagRepo.tagsForTransaction(widget.transaction!.id!);
      selectedTagIds.addAll(existing.map((t) => t.id!));
    }
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _accounts = accounts;
      _tags = tags;
      _selectedTagIds = selectedTagIds;
      if (_categoryId == null && cats.isNotEmpty) _categoryId = cats.first.id;
      _accountId ??= accounts.isNotEmpty ? accounts.first.id : null;
      _loading = false;
    });
  }

  Future<void> _loadCategories() async {
    final cats = await _catRepo.getByType(_type);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (_categoryId == null && cats.isNotEmpty) _categoryId = cats.first.id;
    });
  }

  Future<void> _save({bool keepAdding = false}) async {
    final cents = parseAmountToCents(_amountController.text);
    if (cents == null || cents == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择分类')));
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final date = DateFormat('yyyy-MM-dd').format(_date);
    final t = Transaction(
      id: widget.transaction?.id,
      type: _type,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存，继续记下一笔')));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _accountName() {
    for (final a in _accounts) {
      if (a.id == _accountId) return a.name;
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
                _buildTypeSwitcher(),
                _buildAmountField(),
                Expanded(child: _buildCategoryGrid()),
                _buildFields(),
                _buildActions(),
              ],
            ),
    );
  }

  Widget _buildTypeSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SegmentedButton<TxType>(
        segments: const [
          ButtonSegment(value: TxType.expense, label: Text('支出')),
          ButtonSegment(value: TxType.income, label: Text('收入')),
        ],
        selected: {_type},
        onSelectionChanged: (s) {
          setState(() {
            _type = s.first;
            _categoryId = null;
          });
          _loadCategories();
        },
      ),
    );
  }

  Widget _buildAmountField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _amountController,
        autofocus: true,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          prefixText: '¥ ',
          hintText: '0.00',
          border: InputBorder.none,
        ),
      ),
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

  Widget _buildFields() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(child: _fieldChip(Icons.account_balance_wallet_outlined, _accountName(), _pickAccount)),
          Expanded(child: _fieldChip(Icons.event_outlined, DateFormat('MM-dd HH:mm').format(_date), _pickDate)),
          Expanded(
            child: _fieldChip(
              Icons.edit_note_outlined,
              _noteController.text.isEmpty ? '备注' : _noteController.text,
              _pickNote,
            ),
          ),
          if (_tags.isNotEmpty)
            Expanded(
              child: _fieldChip(
                Icons.sell_outlined,
                _selectedTagIds.isEmpty ? '标签' : '${_selectedTagIds.length}个标签',
                _pickTags,
              ),
            ),
        ],
      ),
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

  Widget _buildActions() {
    final editing = widget.transaction != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          if (!editing) ...[
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
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(editing ? '保存' : '保存')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAccount() async {
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
                  trailing: a.id == _accountId ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () => Navigator.pop(context, a.id),
                )),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _accountId = selected);
  }

  Future<void> _pickDate() async {
    final picked = await showWheelDatePicker(context, initialDate: _date, withTime: true);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickNote() async {
    final controller = TextEditingController(text: _noteController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('备注'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '输入备注')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('确定')),
        ],
      ),
    );
    if (result != null) setState(() => _noteController.text = result);
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
