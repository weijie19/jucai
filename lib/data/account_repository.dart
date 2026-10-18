import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/models.dart';
import '../services/balance.dart';
import 'database.dart';

class AccountRepository {
  Future<List<Account>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('accounts', orderBy: 'sort_order, id');
    return rows.map(Account.fromMap).toList();
  }

  Future<Account?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Account.fromMap(rows.first);
  }

  Future<Account> insert(Account a) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('accounts', a.toMap()..remove('id'));
    return Account(
      id: id,
      name: a.name,
      type: a.type,
      icon: a.icon,
      color: a.color,
      initialBalanceCents: a.initialBalanceCents,
      sortOrder: a.sortOrder,
    );
  }

  Future<void> update(Account a) async {
    final db = await AppDatabase.instance.database;
    await db.update('accounts', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('accounts');
  }

  Future<int> balance(int accountId) async {
    final initial = (await getById(accountId))?.initialBalanceCents ?? 0;
    final income = await _sum(
      'SELECT COALESCE(SUM(amount_cents),0) FROM transactions WHERE account_id = ? AND type = ?',
      [accountId, TxType.income.name],
    );
    final expense = await _sum(
      'SELECT COALESCE(SUM(amount_cents),0) FROM transactions WHERE account_id = ? AND type = ?',
      [accountId, TxType.expense.name],
    );
    final transferOut = await _sum(
      'SELECT COALESCE(SUM(amount_cents + fee_cents),0) FROM transfers WHERE from_account_id = ?',
      [accountId],
    );
    final transferIn = await _sum(
      'SELECT COALESCE(SUM(amount_cents),0) FROM transfers WHERE to_account_id = ?',
      [accountId],
    );
    return computeBalance(
      initial: initial,
      income: income,
      expense: expense,
      transferOut: transferOut,
      transferIn: transferIn,
    );
  }

  Future<int> _sum(String sql, List<Object?> args) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(sql, args);
    return rows.first.values.first as int? ?? 0;
  }
}
