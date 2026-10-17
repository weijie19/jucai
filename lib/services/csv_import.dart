import 'package:csv/csv.dart';
import '../models/models.dart';
import 'amount.dart';

class ParsedCsvRow {
  final String? date;
  final TxType type;
  final int amountCents;
  final String? categoryName;
  final String? note;
  final String? account;
  final String? error;

  const ParsedCsvRow({
    required this.date,
    required this.type,
    required this.amountCents,
    this.categoryName,
    this.note,
    this.account,
    this.error,
  });

  bool get ok => error == null && date != null;
}

/// 把 CSV 文本解析成 [ParsedCsvRow] 列表。
/// 通过表头自动识别列，兼容挖财常见的列名（日期/类型/分类/金额/备注/账户）。
List<ParsedCsvRow> parseCsvContent(String content) {
  final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rows = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(normalized.trim());

  if (rows.isEmpty) return const [];

  final header = rows.first.map((e) => e.toString().trim()).toList();
  final idx = _detectColumns(header);
  if (idx == null) {
    return const [ParsedCsvRow(date: null, type: TxType.expense, amountCents: 0, error: '无法识别表头列')];
  }

  final result = <ParsedCsvRow>[];
  for (var i = 1; i < rows.length; i++) {
    final cells = rows[i];
    String cell(int col) {
      if (col < 0 || col >= cells.length) return '';
      return cells[col].toString().trim();
    }

    final dateStr = cell(idx.date);
    final amountStr = cell(idx.amount);
    final typeStr = cell(idx.type);
    final catStr = cell(idx.category);
    final noteStr = cell(idx.note);
    final accountStr = cell(idx.account);

    final cents = parseAmountToCents(amountStr);
    if (dateStr.isEmpty || cents == null) {
      result.add(ParsedCsvRow(
        date: dateStr.isEmpty ? null : dateStr,
        type: TxType.expense,
        amountCents: 0,
        categoryName: catStr.isEmpty ? null : catStr,
        note: noteStr.isEmpty ? null : noteStr,
        account: accountStr.isEmpty ? null : accountStr,
        error: '金额或日期无法解析',
      ));
      continue;
    }

    TxType type;
    if (typeStr.isNotEmpty) {
      final t = typeStr.toLowerCase();
      final isIncome = t.contains('收') || t == 'income' || t == 'in';
      type = isIncome ? TxType.income : TxType.expense;
    } else {
      type = cents < 0 ? TxType.expense : TxType.income;
    }

    result.add(ParsedCsvRow(
      date: dateStr,
      type: type,
      amountCents: cents.abs(),
      categoryName: catStr.isEmpty ? null : catStr,
      note: noteStr.isEmpty ? null : noteStr,
      account: accountStr.isEmpty ? null : accountStr,
    ));
  }
  return result;
}

class _Columns {
  final int date;
  final int type;
  final int category;
  final int amount;
  final int note;
  final int account;
  const _Columns({
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    required this.note,
    required this.account,
  });
}

_Columns? _detectColumns(List<String> header) {
  int find(List<String> keys) {
    for (var i = 0; i < header.length; i++) {
      final h = header[i];
      for (final k in keys) {
        if (h.contains(k)) return i;
      }
    }
    return -1;
  }

  final date = find(['日期', '时间', 'date']);
  final amount = find(['金额', 'amount']);
  if (date < 0 || amount < 0) return null;

  return _Columns(
    date: date,
    type: find(['类型', '收支', 'type']),
    category: find(['分类', '类别', 'category']),
    amount: amount,
    note: find(['备注', '描述', 'note', '说明']),
    account: find(['账户', '账号', 'account']),
  );
}

/// 把 CSV 里的日期字符串规范为 yyyy-MM-dd。无法解析返回 null。
String? normalizeDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final m = RegExp(r'(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(s);
  if (m == null) return null;
  final y = m.group(1)!;
  final mo = m.group(2)!.padLeft(2, '0');
  final d = m.group(3)!.padLeft(2, '0');
  return '$y-$mo-$d';
}
