import '../models/transfer.dart';
import 'database.dart';

class TransferRepository {
  Future<Transfer> insert(Transfer t) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('transfers', t.toMap()..remove('id'));
    return Transfer(
      id: id,
      fromAccountId: t.fromAccountId,
      toAccountId: t.toAccountId,
      amountCents: t.amountCents,
      feeCents: t.feeCents,
      date: t.date,
      note: t.note,
    );
  }

  Future<List<Transfer>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('transfers', orderBy: 'date DESC, id DESC');
    return rows.map(Transfer.fromMap).toList();
  }

  Future<List<Transfer>> getByAccount(int accountId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'transfers',
      where: 'from_account_id = ? OR to_account_id = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Transfer.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('transfers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('transfers');
  }
}
