import 'package:flutter/material.dart';
import '../data/budget_repository.dart';
import '../data/category_repository.dart';
import '../models/budget.dart';
import '../models/models.dart';
import '../services/amount.dart';
import '../widgets/category_icons.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetRepo = BudgetRepository();
  final _catRepo = CategoryRepository();
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final budgets = await _budgetRepo.getAll();
    final categories = await _catRepo.getByType(TxType.expense);
    if (!mounted) return;
    setState(() {
      _budgets = budgets;
      _categories = categories;
      _loading = false;
    });
  }

  Future<void> _edit(Budget? existing, {Category? category}) async {
    final controller = TextEditingController(
      text: existing == null ? '' : formatCents(existing.amountCents),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? '设置月总预算' : '设置「${category.name}」预算'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '¥ ', hintText: '0.00'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final cents = parseAmountToCents(controller.text);
              Navigator.pop(context, cents);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await _budgetRepo.upsert(Budget(
      id: existing?.id,
      categoryId: category?.id,
      amountCents: result,
    ));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('预算')), body: const Center(child: CircularProgressIndicator()));
    }
    final totalBudget = _budgets.where((b) => b.categoryId == null).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('预算')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('月总预算', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (totalBudget.isEmpty)
            OutlinedButton(onPressed: () => _edit(null), child: const Text('设置月总预算'))
          else
            Card(
              child: ListTile(
                title: Text('¥${formatCents(totalBudget.first.amountCents)}'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _edit(totalBudget.first),
              ),
            ),
          const Divider(height: 32),
          Text('分类预算', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._categories.map((c) {
            final b = _budgets.where((x) => x.categoryId == c.id).toList();
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(c.color),
                  child: Icon(iconFor(c.icon), color: Colors.white, size: 20),
                ),
                title: Text(c.name),
                subtitle: Text(b.isEmpty ? '未设置' : '¥${formatCents(b.first.amountCents)}'),
                onTap: () => _edit(b.isEmpty ? null : b.first, category: c),
              ),
            );
          }),
        ],
      ),
    );
  }
}
