import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/models/models.dart';
import 'package:jucai/models/periodic_plan.dart';
import 'package:jucai/services/plan_scheduler.dart';

void main() {
  test('PeriodicPlan 序列化往返一致（月付）', () {
    const p = PeriodicPlan(
      id: 1,
      name: '房租',
      type: TxType.expense,
      amountCents: 300000,
      categoryId: 4,
      accountId: 2,
      period: 'monthly',
      day: 15,
      note: '押一付三',
      enabled: true,
      lastRunDate: '2026-10-15',
      createdAt: 1700000000000,
    );
    final back = PeriodicPlan.fromMap(p.toMap());
    expect(back.id, 1);
    expect(back.name, '房租');
    expect(back.type, TxType.expense);
    expect(back.amountCents, 300000);
    expect(back.categoryId, 4);
    expect(back.accountId, 2);
    expect(back.period, 'monthly');
    expect(back.day, 15);
    expect(back.month, null);
    expect(back.note, '押一付三');
    expect(back.enabled, true);
    expect(back.lastRunDate, '2026-10-15');
    expect(back.createdAt, 1700000000000);
  });

  test('PeriodicPlan 序列化往返一致（年付带月份）', () {
    const p = PeriodicPlan(
      name: '车险',
      type: TxType.expense,
      amountCents: 500000,
      categoryId: 8,
      period: 'yearly',
      day: 20,
      month: 6,
      enabled: false,
      createdAt: 1700000000000,
    );
    final back = PeriodicPlan.fromMap(p.toMap());
    expect(back.id, null);
    expect(back.period, 'yearly');
    expect(back.month, 6);
    expect(back.day, 20);
    expect(back.enabled, false);
  });

  test('nextRunDate 每月：日期未到则取本月，已过则取下月', () {
    const plan = PeriodicPlan(
      name: '房租',
      type: TxType.expense,
      amountCents: 100,
      categoryId: 1,
      period: 'monthly',
      day: 10,
      createdAt: 0,
    );
    expect(nextRunDate(plan, DateTime(2026, 10, 5)), DateTime(2026, 10, 10));
    expect(nextRunDate(plan, DateTime(2026, 10, 15)), DateTime(2026, 11, 10));
    // 恰好当天，视为已执行过，顺延到下月
    expect(nextRunDate(plan, DateTime(2026, 10, 10)), DateTime(2026, 11, 10));
  });

  test('nextRunDate 每月：31号自动收敛到28号', () {
    const plan = PeriodicPlan(
      name: '房贷',
      type: TxType.expense,
      amountCents: 100,
      categoryId: 1,
      period: 'monthly',
      day: 31,
      createdAt: 0,
    );
    expect(nextRunDate(plan, DateTime(2026, 10, 20)), DateTime(2026, 10, 28));
  });

  test('nextRunDate 每周：按周一=1对齐', () {
    const plan = PeriodicPlan(
      name: '健身',
      type: TxType.expense,
      amountCents: 100,
      categoryId: 1,
      period: 'weekly',
      day: 1,
      createdAt: 0,
    );
    // 2026-10-19 是周一
    expect(nextRunDate(plan, DateTime(2026, 10, 18)), DateTime(2026, 10, 19));
    // 恰好当天，顺延到下周
    expect(nextRunDate(plan, DateTime(2026, 10, 19)), DateTime(2026, 10, 26));
    // 2026-10-20 是周二，应取本周一的下一个周一
    expect(nextRunDate(plan, DateTime(2026, 10, 20)), DateTime(2026, 10, 26));
  });

  test('nextRunDate 每年：按月份日期对齐', () {
    const plan = PeriodicPlan(
      name: '车险',
      type: TxType.expense,
      amountCents: 100,
      categoryId: 1,
      period: 'yearly',
      day: 15,
      month: 6,
      createdAt: 0,
    );
    expect(nextRunDate(plan, DateTime(2026, 1, 1)), DateTime(2026, 6, 15));
    expect(nextRunDate(plan, DateTime(2026, 10, 20)), DateTime(2027, 6, 15));
  });

  test('nextRunDate 未知周期返回 null', () {
    const plan = PeriodicPlan(
      name: '异常',
      type: TxType.expense,
      amountCents: 100,
      categoryId: 1,
      period: 'daily',
      day: 1,
      createdAt: 0,
    );
    expect(nextRunDate(plan, DateTime(2026, 10, 20)), null);
  });
}
