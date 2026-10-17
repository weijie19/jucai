import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/models/models.dart';
import 'package:jucai/services/csv_import.dart';

void main() {
  group('parseCsvContent', () {
    test('解析挖财风格 CSV', () {
      const csv = '日期,类型,分类,金额,备注,账户\n'
          '2022-05-17,支出,餐饮,12.50,午饭,支付宝\n'
          '2022-05-18,收入,工资,8000,五月工资,银行卡\n';
      final rows = parseCsvContent(csv);
      expect(rows.length, 2);
      expect(rows[0].date, '2022-05-17');
      expect(rows[0].type, TxType.expense);
      expect(rows[0].amountCents, 1250);
      expect(rows[0].categoryName, '餐饮');
      expect(rows[0].note, '午饭');
      expect(rows[0].account, '支付宝');
      expect(rows[1].type, TxType.income);
      expect(rows[1].amountCents, 800000);
    });

    test('金额带负号自动判定支出', () {
      const csv = '日期,金额\n2022-05-17,-12.50\n';
      final rows = parseCsvContent(csv);
      expect(rows[0].type, TxType.expense);
      expect(rows[0].amountCents, 1250);
    });

    test('无法识别表头返回错误', () {
      const csv = 'A,B\n1,2\n';
      final rows = parseCsvContent(csv);
      expect(rows.first.ok, false);
      expect(rows.first.error, isNotNull);
    });
  });

  group('normalizeDate', () {
    test('多种日期格式', () {
      expect(normalizeDate('2022-05-17'), '2022-05-17');
      expect(normalizeDate('2022/5/7'), '2022-05-07');
      expect(normalizeDate('2022.5.17'), '2022-05-17');
      expect(normalizeDate('abc'), null);
    });
  });
}
