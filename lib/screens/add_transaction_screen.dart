import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/category_repository.dart';
import '../data/transaction_repository.dart';
import '../models/models.dart';
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

  TxType _type = TxType.expense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _accountController = TextEditingController();
  DateTime _date = DateTime.now();
  List<Category> _categories = [];
  int? _categoryId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _type = t.type;
      _amountController.text = formatCents(t.amountCents);
      _noteController.text = t.note ?? '';
      _accountController.text = t.account ?? '';
      _date = DateTime.parse(t.date);
      _categoryId = t.categoryId;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _catRepo.getByType(_type);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (_categoryId == null && cats.isNotEmpty) _categoryId = cats.first.id;
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
      date: date,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      account: _accountController.text.trim().isEmpty ? null : _accountController.text.trim(),
      createdAt: widget.transaction?.createdAt ?? now,
      updatedAt: now,
    );
    if (widget.transaction == null) {
      await _txRepo.insert(t);
    } else {
      await _txRepo.update(t);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _accountController.dispose();
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
                TextField(
                  controller: _accountController,
                  decoration: const InputDecoration(labelText: '支付方式（可选）'),
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
}
