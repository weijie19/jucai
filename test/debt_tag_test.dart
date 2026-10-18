import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/models/debt.dart';
import 'package:jucai/models/debt_repayment.dart';
import 'package:jucai/models/tag.dart';

void main() {
  test('Debt 序列化往返一致', () {
    const d = Debt(
      id: 1,
      direction: DebtDirection.lend,
      counterparty: '张三',
      totalCents: 100000,
      remainingCents: 60000,
      accountId: 2,
      date: '2026-10-18',
      note: '借给张三',
      status: DebtStatus.open,
      createdAt: 1,
      updatedAt: 2,
    );
    final back = Debt.fromMap(d.toMap());
    expect(back.id, 1);
    expect(back.direction, DebtDirection.lend);
    expect(back.counterparty, '张三');
    expect(back.totalCents, 100000);
    expect(back.remainingCents, 60000);
    expect(back.status, DebtStatus.open);
  });

  test('Debt 剩余未还默认等于总额', () {
    const d = Debt(
      direction: DebtDirection.borrow,
      counterparty: '李四',
      totalCents: 50000,
      date: '2026-10-18',
      createdAt: 1,
      updatedAt: 1,
    );
    expect(d.toMap()['remaining_cents'], 50000);
  });

  test('DebtRepayment 序列化往返一致', () {
    const r = DebtRepayment(
      id: 1,
      debtId: 3,
      amountCents: 40000,
      date: '2026-10-20',
      accountId: 2,
      note: '还一部分',
      createdAt: 1,
    );
    final back = DebtRepayment.fromMap(r.toMap());
    expect(back.debtId, 3);
    expect(back.amountCents, 40000);
    expect(back.accountId, 2);
  });

  test('Tag 序列化往返一致', () {
    const t = Tag(id: 1, name: '报销', color: 0xFF42A5F5, createdAt: 1);
    final back = Tag.fromMap(t.toMap());
    expect(back.name, '报销');
    expect(back.color, 0xFF42A5F5);
  });
}
