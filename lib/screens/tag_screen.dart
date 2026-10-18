import 'package:flutter/material.dart';
import '../data/tag_repository.dart';
import '../models/tag.dart';

const List<int> tagPalette = [
  0xFFEF5350,
  0xFFEC407A,
  0xFFAB47BC,
  0xFF7E57C2,
  0xFF5C6BC0,
  0xFF42A5F5,
  0xFF29B6F6,
  0xFF26C6DA,
  0xFF26A69A,
  0xFF66BB6A,
  0xFF9CCC65,
  0xFFFFCA28,
  0xFFFFA726,
  0xFFFF7043,
  0xFF8D6E63,
  0xFF90A4AE,
];

class TagScreen extends StatefulWidget {
  const TagScreen({super.key});

  @override
  State<TagScreen> createState() => _TagScreenState();
}

class _TagScreenState extends State<TagScreen> {
  final _repo = TagRepository();
  List<Tag> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final tags = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _tags = tags;
      _loading = false;
    });
  }

  Future<void> _edit([Tag? existing]) async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (_) => _TagDialog(tag: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _repo.insert(result);
    } else {
      await _repo.update(result);
    }
    _reload();
  }

  Future<void> _confirmDelete(Tag t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除标签「${t.name}」？'),
        content: const Text('流水会保留，只是去掉这个标签。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.delete(t.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('标签')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? const Center(child: Text('还没有标签，点右下角 + 新建'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _tags.map((t) => Card(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Color(t.color), radius: 12),
                          title: Text(t.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _edit(t),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(t),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TagDialog extends StatefulWidget {
  final Tag? tag;
  const _TagDialog({this.tag});

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late final TextEditingController _name;
  int _color = tagPalette.first;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.tag?.name ?? '');
    _color = widget.tag?.color ?? tagPalette.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag == null ? '新建标签' : '编辑标签'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: '标签名'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tagPalette.map((c) {
              final selected = c == _color;
              return InkWell(
                onTap: () => setState(() => _color = c),
                child: CircleAvatar(
                  backgroundColor: Color(c),
                  radius: 16,
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              Tag(
                id: widget.tag?.id,
                name: name,
                color: _color,
                createdAt: widget.tag?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
