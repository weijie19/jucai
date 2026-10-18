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
}
