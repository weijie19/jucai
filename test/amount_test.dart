import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/services/amount.dart';

void main() {
  group('parseAmountToCents', () {
    test('整数', () {
      expect(parseAmountToCents('12'), 1200);
    });
    test('小数', () {
      expect(parseAmountToCents('12.5'), 1250);
      expect(parseAmountToCents('0.05'), 5);
    });
    test('负数', () {
      expect(parseAmountToCents('-3'), -300);
      expect(parseAmountToCents('-3.50'), -350);
    });
    test('带符号与千分位', () {
      expect(parseAmountToCents('¥1,234.56'), 123456);
      expect(parseAmountToCents('1 234.56'), 123456);
      expect(parseAmountToCents('+5.00'), 500);
    });
    test('非法输入返回 null', () {
      expect(parseAmountToCents(''), null);
      expect(parseAmountToCents('abc'), null);
      expect(parseAmountToCents('1.2.3'), null);
    });
  });

  group('formatCents', () {
    test('格式化', () {
      expect(formatCents(1234), '12.34');
      expect(formatCents(5), '0.05');
      expect(formatCents(-350), '-3.50');
    });
  });
}
