import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/services/budget.dart';

void main() {
  test('预算进度正常情况', () {
    expect(budgetRatio(10000, 2500), closeTo(0.25, 0.001));
    expect(budgetRatio(10000, 10000), 1.0);
  });

  test('超支封顶为 1.0', () {
    expect(budgetRatio(10000, 15000), 1.0);
  });

  test('预算为 0 返回 0', () {
    expect(budgetRatio(0, 500), 0);
  });
}
