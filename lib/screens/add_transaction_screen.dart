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
      _date = DateTime.parse(t.date);
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

  Future<void> _save() async {
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
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.transaction == null ? '记一笔' : '编辑记录')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<TxType>(
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
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 28),
                  decoration: const InputDecoration(prefixText: '¥ ', hintText: '0.00'),
                ),
                const SizedBox(height: 24),
                Text('分类', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final selected = c.id == _categoryId;
                    return ChoiceChip(
                      avatar: Icon(iconFor(c.icon), size: 18, color: selected ? Colors.white : Color(c.color)),
                      label: Text(c.name),
                      selected: selected,
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text('账户', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _accounts.map((a) {
                    final selected = a.id == _accountId;
                    return ChoiceChip(
                      avatar: Icon(iconFor(a.icon), size: 18, color: selected ? Colors.white : Color(a.color)),
                      label: Text(a.name),
                      selected: selected,
                      onSelected: (_) => setState(() => _accountId = a.id),
                    );
                  }).toList(),
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('标签', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      final selected = _selectedTagIds.contains(tag.id);
                      return FilterChip(
                        label: Text(tag.name),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedTagIds.add(tag.id!);
                            } else {
                              _selectedTagIds.remove(tag.id!);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
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
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _save,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('保存'),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _loadCategories() async {
    final cats = await _catRepo.getByType(_type);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (_categoryId == null && cats.isNotEmpty) _categoryId = cats.first.id;
    });
  }
}
