import 'package:flutter/material.dart';
import '../data/category_repository.dart';
import '../models/models.dart';
import '../widgets/category_icons.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _repo = CategoryRepository();
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final cats = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expense = _categories.where((c) => c.type == TxType.expense).toList();
    final income = _categories.where((c) => c.type == TxType.income).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('分类管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(null),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _section('支出分类', expense),
                _section('收入分类', income),
              ],
            ),
    );
  }

  Widget _section(String title, List<Category> cats) {
    final parents = cats.where((c) => c.parentId == null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.labelLarge),
        ),
        ...parents.expand((p) {
          final children = cats.where((c) => c.parentId == p.id).toList();
          return [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(p.color),
                child: Icon(iconFor(p.icon), color: Colors.white, size: 20),
              ),
              title: Text(p.name),
              onTap: () => _edit(p),
            ),
            ...children.map((child) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 48),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(child.color),
                    child: Icon(iconFor(child.icon), color: Colors.white, size: 14),
                  ),
                  title: Text(child.name, style: const TextStyle(fontSize: 14)),
                  onTap: () => _edit(child),
                )),
          ];
        }),
      ],
    );
  }

  Future<void> _edit(Category? existing) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => CategoryEditDialog(category: existing),
    );
    if (result != null) {
      if (existing == null) {
        await _repo.insert(result);
      } else {
        await _repo.update(result);
      }
      _reload();
    }
  }
}

class CategoryEditDialog extends StatefulWidget {
  final Category? category;
  const CategoryEditDialog({super.key, this.category});

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _nameController = TextEditingController();
  TxType _type = TxType.expense;
  String _icon = 'more_horiz';
  int _color = 0xFF90A4AE;
  int? _parentId;
  List<Category> _allCats = [];
  final _repo = CategoryRepository();

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    if (c != null) {
      _nameController.text = c.name;
      _type = c.type;
      _icon = c.icon;
      _color = c.color;
      _parentId = c.parentId;
    }
    _loadCats();
  }

  Future<void> _loadCats() async {
    final cats = await _repo.getAll();
    if (!mounted) return;
    setState(() => _allCats = cats);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final cat = Category(
      id: widget.category?.id,
      name: name,
      type: _type,
      icon: _icon,
      color: _color,
      sortOrder: widget.category?.sortOrder ?? 100,
      parentId: _parentId,
    );
    Navigator.pop(context, cat);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? '新增分类' : '编辑分类'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(value: TxType.expense, label: Text('支出')),
                ButtonSegment(value: TxType.income, label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _parentId = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _parentId,
              decoration: const InputDecoration(labelText: '所属大类（可选）'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('无（作为大类）')),
                ..._allCats
                    .where((c) => c.type == _type && c.parentId == null)
                    .map((p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.name))),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectableIconKeys.map((key) {
                return InkWell(
                  onTap: () => setState(() => _icon = key),
                  child: CircleAvatar(
                    backgroundColor: _icon == key ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                    child: Icon(iconFor(key), color: _icon == key ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        if (widget.category != null)
          TextButton(
            onPressed: () async {
              await _repo.delete(widget.category!.id!);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
