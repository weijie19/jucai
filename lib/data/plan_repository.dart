import 'package:intl/intl.dart';
import '../models/models.dart';
import '../models/periodic_plan.dart';
import '../services/plan_scheduler.dart';
import 'database.dart';
import 'transaction_repository.dart';

class PlanRepository {
  Future<List<PeriodicPlan>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('periodic_plans', orderBy: 'id');
    return rows.map(PeriodicPlan.fromMap).toList();
  }

  Future<int> insert(PeriodicPlan p) async {
    final db = await AppDatabase.instance.database;
    final map = p.toMap();
    if (p.id == null) map.remove('id');
    return db.insert('periodic_plans', map);
  }

  Future<void> update(PeriodicPlan p) async {
    final db = await AppDatabase.instance.database;
    await db.update('periodic_plans', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('periodic_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('periodic_plans');
  }

  /// 把到期的周期账自动记入流水，返回本次入账笔数。
  Future<int> runDuePlans({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final txRepo = TransactionRepository();
    final db = await AppDatabase.instance.database;
    final ts = DateTime.now().millisecondsSinceEpoch;
    var count = 0;
    for (final plan in await getAll()) {
      if (!plan.enabled) continue;
      var cursor = plan.lastRunDate != null
          ? DateTime.parse(plan.lastRunDate!)
          : DateTime.fromMillisecondsSinceEpoch(plan.createdAt);
      var guard = 0;
      while (guard++ < 60) {
        final next = nextRunDate(plan, cursor);
        if (next == null) break;
        if (next.isAfter(today)) break;
        final nextStr = DateFormat('yyyy-MM-dd').format(next);
        await txRepo.insert(Transaction(
          type: plan.type,
          amountCents: plan.amountCents,
          categoryId: plan.categoryId,
          accountId: plan.accountId,
          date: nextStr,
          note: plan.note,
          createdAt: ts,
          updatedAt: ts,
        ));
        await db.update('periodic_plans', {'last_run_date': nextStr}, where: 'id = ?', whereArgs: [plan.id]);
        cursor = next;
        count++;
      }
    }
    return count;
  }
}
