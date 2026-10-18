import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/models/account.dart';
import 'package:jucai/models/budget.dart';
import 'package:jucai/models/transfer.dart';

void main() {
  test('Account 序列化往返一致', () {
    const a = Account(
      id: 3,
      name: '支付宝',
      type: AccountType.alipay,
      icon: 'account_balance_wallet',
      color: 0xFF1E88E5,
      initialBalanceCents: 5000,
      sortOrder: 2,
    );
    final back = Account.fromMap(a.toMap());
    expect(back.id, 3);
    expect(back.name, '支付宝');
    expect(back.type, AccountType.alipay);
    expect(back.initialBalanceCents, 5000);
    expect(back.sortOrder, 2);
  });

  test('Transfer 序列化往返一致', () {
    const t = Transfer(
      id: 1,
      fromAccountId: 2,
      toAccountId: 3,
      amountCents: 10000,
      feeCents: 100,
      date: '2026-10-18',
      note: '转给储蓄',
    );
    final back = Transfer.fromMap(t.toMap());
    expect(back.fromAccountId, 2);
    expect(back.toAccountId, 3);
    expect(back.amountCents, 10000);
    expect(back.feeCents, 100);
    expect(back.date, '2026-10-18');
  });

  test('Budget 序列化往返一致（分类预算与总预算）', () {
    final total = Budget.fromMap(const Budget(amountCents: 300000).toMap());
    expect(total.categoryId, null);
    expect(total.amountCents, 300000);

    final cat = Budget.fromMap(const Budget(categoryId: 5, amountCents: 50000).toMap());
    expect(cat.categoryId, 5);
    expect(cat.amountCents, 50000);
  });
}
