import 'package:sqflite/sqflite.dart';
import '../models/budget.dart';
import 'database.dart';

class BudgetRepository {
  Future<List<Budget>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('budgets', orderBy: 'id');
    return rows.map(Budget.fromMap).toList();
  }

  Future<Budget> upsert(Budget b) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'budgets',
      where: b.categoryId == null ? 'category_id IS NULL' : 'category_id = ?',
      whereArgs: b.categoryId == null ? null : [b.categoryId],
    );
    if (rows.isEmpty) {
      final id = await db.insert('budgets', b.toMap()..remove('id'));
      return Budget(id: id, categoryId: b.categoryId, amountCents: b.amountCents);
    }
    final id = rows.first['id'] as int;
    await db.update('budgets', {'amount_cents': b.amountCents}, where: 'id = ?', whereArgs: [id]);
    return Budget(id: id, categoryId: b.categoryId, amountCents: b.amountCents);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('budgets');
  }

  /// 当前月已花费（categoryId 为空 = 全部支出）。
  Future<int> spentThisMonth(int year, int month, {int? categoryId}) async {
    final db = await AppDatabase.instance.database;
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final next = month == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_cents),0) AS s FROM transactions '
      'WHERE type = ? AND date >= ? AND date < ?'
      '${categoryId == null ? '' : ' AND category_id = ?'}',
      [
        'expense',
        start,
        next,
        if (categoryId != null) categoryId,
      ],
    );
    return rows.first['s'] as int? ?? 0;
  }
}
