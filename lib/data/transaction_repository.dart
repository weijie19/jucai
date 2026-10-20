import '../models/models.dart';
import 'database.dart';

class TransactionRepository {
  Future<Transaction> insert(Transaction t) async {
    final db = await AppDatabase.instance.database;
    final map = t.toMap();
    if (t.id == null) map.remove('id');
    final id = await db.insert('transactions', map);
    return Transaction(
      id: id,
      type: t.type,
      amountCents: t.amountCents,
      categoryId: t.categoryId,
      date: t.date,
      time: t.time,
      note: t.note,
      accountId: t.accountId,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
    );
  }

  Future<void> update(Transaction t) async {
    final db = await AppDatabase.instance.database;
    await db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('transactions');
  }

  Future<void> insertAll(List<Transaction> list) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final t in list) {
      batch.insert('transactions', t.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  Future<List<Transaction>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  Future<List<Transaction>> getByMonth(int year, int month) async {
    final db = await AppDatabase.instance.database;
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final next = month == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';
    final rows = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, next],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<List<Transaction>> getByAccount(int accountId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<int> sumByMonth(TxType type, int year, int month) async {
    final db = await AppDatabase.instance.database;
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final next = month == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_cents), 0) AS s FROM transactions '
      'WHERE type = ? AND date >= ? AND date < ?',
      [type.name, start, next],
    );
    return rows.first['s'] as int? ?? 0;
  }
}
