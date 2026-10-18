import 'dart:convert';
import 'dart:io';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/account_repository.dart';
import '../data/category_repository.dart';
import '../data/transaction_repository.dart';
import '../models/account.dart';
import '../models/models.dart';
import '../services/amount.dart';
import '../services/csv_import.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _catRepo = CategoryRepository();
  final _txRepo = TransactionRepository();

  List<ParsedCsvRow>? _rows;
  String? _fileName;
  bool _importing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final bytes = await File(path).readAsBytes();
    final content = _decode(bytes);
    final rows = parseCsvContent(content);
    setState(() {
      _rows = rows;
      _fileName = result.files.single.name;
    });
  }

  String _decode(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return gbk.decode(bytes);
    }
  }

  Future<void> _import() async {
    final rows = _rows!;
    final valid = rows.where((r) => r.ok).toList();
    if (valid.isEmpty) return;

    setState(() => _importing = true);

    final existing = await _catRepo.getAll();
    final nameToId = <String, int>{};
    for (final c in existing) {
      nameToId['${c.type.name}|${c.name}'] = c.id!;
    }

    final accountRepo = AccountRepository();
    final existingAccounts = await accountRepo.getAll();
    final accountNameToId = <String, int>{
      for (final a in existingAccounts) a.name: a.id!,
    };

    var imported = 0;
    for (final r in valid) {
      final date = normalizeDate(r.date!);
      if (date == null) continue;
      var categoryId = nameToId['${r.type.name}|${r.categoryName ?? ''}'];
      if (categoryId == null) {
        final cat = await _catRepo.insert(Category(
          name: r.categoryName?.isNotEmpty == true ? r.categoryName! : '其他',
          type: r.type,
          icon: 'more_horiz',
          color: 0xFF90A4AE,
          sortOrder: 100,
        ));
        categoryId = cat.id!;
        nameToId['${r.type.name}|${r.categoryName ?? ''}'] = categoryId;
      }
      final accountName = r.account?.trim();
      int? accountId;
      if (accountName != null && accountName.isNotEmpty) {
        accountId = accountNameToId[accountName];
        if (accountId == null) {
          final acc = await accountRepo.insert(Account(
            name: accountName,
            type: AccountType.other,
            icon: 'account_balance',
            color: 0xFF90A4AE,
            sortOrder: 100,
          ));
          accountId = acc.id!;
          accountNameToId[accountName] = accountId;
        }
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      await _txRepo.insert(Transaction(
        type: r.type,
        amountCents: r.amountCents,
        categoryId: categoryId,
        date: date,
        note: r.note,
        accountId: accountId,
        createdAt: now,
        updatedAt: now,
      ));
      imported++;
    }

    if (!mounted) return;
    setState(() => _importing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功导入 $imported 条记录')));
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final okCount = rows == null ? 0 : rows.where((r) => r.ok).length;
    final errCount = rows == null ? 0 : rows.where((r) => !r.ok).length;

    return Scaffold(
      appBar: AppBar(title: const Text('导入账单')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_fileName == null ? '选择挖财导出的 CSV 文件' : _fileName!),
            ),
            const SizedBox(height: 16),
            if (rows != null) ...[
              Text('预览：共 ${rows.length} 行，可导入 $okCount 行，失败 $errCount 行'),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: rows.length > 50 ? 50 : rows.length,
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(r.ok ? Icons.check_circle : Icons.error, color: r.ok ? Colors.green : Colors.red),
                      title: Text('${r.date ?? '?'}  ${r.categoryName ?? ''}  ${formatCents(r.amountCents)}'),
                      subtitle: Text(r.error ?? r.note ?? ''),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _importing || okCount == 0 ? null : _import,
                child: Text(_importing ? '导入中…' : '导入 $okCount 条'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
