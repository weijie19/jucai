import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/account_repository.dart';
import '../data/category_repository.dart';
import '../data/plan_repository.dart';
import '../models/account.dart';
import '../models/models.dart';
import '../models/periodic_plan.dart';
import '../services/amount.dart';
import '../services/plan_scheduler.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final _repo = PlanRepository();
  final _catRepo = CategoryRepository();
  final _accountRepo = AccountRepository();
  List<PeriodicPlan> _plans = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final plans = await _repo.getAll();
    final cats = await _catRepo.getAll();
    final accounts = await _accountRepo.getAll();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _categories = cats;
      _accounts = accounts;
      _loading = false;
    });
  }

  String _catName(int id) {
    for (final c in _categories) {
      if (c.id == id) return c.name;
    }
    return '未分类';
  }

  Future<void> _edit([PeriodicPlan? existing]) async {
    final result = await showDialog<PeriodicPlan>(
      context: context,
      builder: (_) => _PlanDialog(plan: existing, categories: _categories, accounts: _accounts),
    );
    if (result == null) return;
    if (existing == null) {
      await _repo.insert(result);
    } else {
      await _repo.update(result);
    }
    _reload();
  }

  Future<void> _toggle(PeriodicPlan p, bool on) async {
    await _repo.update(p.copyWith(enabled: on));
    _reload();
  }

  Future<void> _confirmDelete(PeriodicPlan p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除计划「${p.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.delete(p.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('计划'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _edit()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('添加房租、工资等定期收支，到期自动记账', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _plans.length,
                  itemBuilder: (context, i) {
                    final p = _plans[i];
                    final next = nextRunDate(p, DateTime.now());
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(_categoryColor(p.categoryId)),
                          child: Text(
                            _catName(p.categoryId).isEmpty ? '?' : _catName(p.categoryId).substring(0, 1),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          [
                            '${p.type == TxType.income ? '收' : '支'} ¥${formatCents(p.amountCents)}',
                            _periodLabel(p),
                            if (next != null) '下次 ${DateFormat('MM-dd').format(next)}',
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(value: p.enabled, onChanged: (v) => _toggle(p, v)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(p),
                            ),
                          ],
                        ),
                        onTap: () => _edit(p),
                      ),
                    );
                  },
                ),
    );
  }

  int _categoryColor(int id) {
    for (final c in _categories) {
      if (c.id == id) return c.color;
    }
    return 0xFF90A4AE;
  }

  String _periodLabel(PeriodicPlan p) {
    switch (p.period) {
      case 'monthly':
        return '每月${p.day}号';
      case 'weekly':
        return '每周${_weekdayName(p.day)}';
      case 'yearly':
        return '每年${p.month ?? 1}月${p.day}日';
      default:
        return '';
    }
  }

  String _weekdayName(int d) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return names[(d - 1).clamp(0, 6)];
  }
}

class _PlanDialog extends StatefulWidget {
  final PeriodicPlan? plan;
  final List<Category> categories;
  final List<Account> accounts;
  const _PlanDialog({this.plan, required this.categories, required this.accounts});

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late TxType _type;
  late String _period;
  int _day = 1;
  int _month = 1;
  int? _categoryId;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _name = TextEditingController(text: p?.name ?? '');
    _amount = TextEditingController(text: p == null ? '' : formatCents(p.amountCents));
    _note = TextEditingController(text: p?.note ?? '');
    _type = p?.type ?? TxType.expense;
    _period = p?.period ?? 'monthly';
    _day = p?.day ?? 1;
    _month = p?.month ?? 1;
    _categoryId = p?.categoryId;
    _accountId = p?.accountId;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<Category> get _typedCategories =>
      widget.categories.where((c) => c.type == _type).toList();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.plan == null ? '新增计划' : '编辑计划'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: '名称（如：房租）'),
            ),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '金额', prefixText: '¥ '),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(value: TxType.expense, label: Text('支出')),
                ButtonSegment(value: TxType.income, label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (s) {
                setState(() {
                  _type = s.first;
                  _categoryId = _typedCategories.isNotEmpty ? _typedCategories.first.id : null;
                });
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _period,
              decoration: const InputDecoration(labelText: '周期'),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('每月')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
                DropdownMenuItem(value: 'yearly', child: Text('每年')),
              ],
              onChanged: (v) => setState(() => _period = v ?? 'monthly'),
            ),
            const SizedBox(height: 8),
            if (_period == 'monthly')
              DropdownButtonFormField<int>(
                initialValue: _day,
                decoration: const InputDecoration(labelText: '每月几号'),
                items: [for (var d = 1; d <= 28; d++) DropdownMenuItem(value: d, child: Text('$d 号'))],
                onChanged: (v) => setState(() => _day = v ?? 1),
              ),
            if (_period == 'weekly')
              DropdownButtonFormField<int>(
                initialValue: _day,
                decoration: const InputDecoration(labelText: '每周几'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('周一')),
                  DropdownMenuItem(value: 2, child: Text('周二')),
                  DropdownMenuItem(value: 3, child: Text('周三')),
                  DropdownMenuItem(value: 4, child: Text('周四')),
                  DropdownMenuItem(value: 5, child: Text('周五')),
                  DropdownMenuItem(value: 6, child: Text('周六')),
                  DropdownMenuItem(value: 7, child: Text('周日')),
                ],
                onChanged: (v) => setState(() => _day = v ?? 1),
              ),
            if (_period == 'yearly') ...[
              DropdownButtonFormField<int>(
                initialValue: _month,
                decoration: const InputDecoration(labelText: '月'),
                items: [for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text('$m 月'))],
                onChanged: (v) => setState(() => _month = v ?? 1),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _day,
                decoration: const InputDecoration(labelText: '日'),
                items: [for (var d = 1; d <= 28; d++) DropdownMenuItem(value: d, child: Text('$d 日'))],
                onChanged: (v) => setState(() => _day = v ?? 1),
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _categoryId ?? _typedCategories.firstOrNull?.id,
              decoration: const InputDecoration(labelText: '分类'),
              items: [
                for (final c in _typedCategories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: '账户（可选）'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('不指定')),
                for (final a in widget.accounts)
                  DropdownMenuItem<int?>(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 8),
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
            final name = _name.text.trim();
            final cents = parseAmountToCents(_amount.text);
            if (name.isEmpty || cents == null || cents == 0) return;
            if (_categoryId == null && _typedCategories.isNotEmpty) {
              _categoryId = _typedCategories.first.id;
            }
            if (_categoryId == null) return;
            final plan = PeriodicPlan(
              id: widget.plan?.id,
              name: name,
              type: _type,
              amountCents: cents.abs(),
              categoryId: _categoryId!,
              accountId: _accountId,
              period: _period,
              day: _day,
              month: _period == 'yearly' ? _month : null,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              enabled: widget.plan?.enabled ?? true,
              lastRunDate: widget.plan?.lastRunDate,
              createdAt: widget.plan?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
            );
            Navigator.pop(context, plan);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
