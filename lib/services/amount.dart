/// 把金额字符串解析为「分」的整数。
/// 支持：`12.5`、`-3`、`¥1,234.56`、`1 234.56`、`+5.00`。
/// 解析失败返回 null。
int? parseAmountToCents(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  s = s.replaceAll('¥', '').replaceAll('￥', '').replaceAll(',', '');
  s = s.replaceAll(RegExp(r'\s'), '');
  if (s.isEmpty) return null;

  final negative = s.startsWith('-');
  if (negative || s.startsWith('+')) {
    s = s.substring(1);
  }

  final parts = s.split('.');
  if (parts.length > 2) return null;
  final intPart = parts[0];
  if (intPart.isEmpty) return null;
  final intVal = int.tryParse(intPart);
  if (intVal == null) return null;

  var cents = intVal * 100;
  if (parts.length == 2) {
    var frac = parts[1];
    if (frac.length == 1) frac = '${frac}0';
    if (frac.length > 2) return null;
    final fracVal = int.tryParse(frac);
    if (fracVal == null) return null;
    cents += fracVal;
  }

  return negative ? -cents : cents;
}

/// 把「分」格式化为字符串，如 1234 -> "12.34"。
String formatCents(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final yuan = abs ~/ 100;
  final fen = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}$yuan.$fen';
}
