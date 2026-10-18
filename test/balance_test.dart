import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/services/balance.dart';

void main() {
  test('余额 = 初始 + 收入 - 支出 - 转出 + 转入', () {
    expect(
      computeBalance(initial: 10000, income: 5000, expense: 2000, transferOut: 3000, transferIn: 1000),
      11000,
    );
  });

  test('全零时为初始余额', () {
    expect(computeBalance(initial: 500, income: 0, expense: 0, transferOut: 0, transferIn: 0), 500);
  });

  test('借贷净影响：借入加、借出减、收还款加、还欠款减', () {
    expect(
      debtNetEffect(borrowTotal: 10000, lendTotal: 5000, lendRepaid: 2000, borrowRepaid: 1000),
      6000, // 10000 - 5000 + 2000 - 1000
    );
  });

  test('借贷净影响全零', () {
    expect(debtNetEffect(borrowTotal: 0, lendTotal: 0, lendRepaid: 0, borrowRepaid: 0), 0);
  });
}
