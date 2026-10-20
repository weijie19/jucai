import '../models/debt.dart';
import '../models/debt_repayment.dart';
import 'database.dart';

class DebtRepository {
  Future<List<Debt>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('debts', orderBy: 'date DESC, id DESC');
    return rows.map(Debt.fromMap).toList();
  }

  Future<Debt?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('debts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Debt.fromMap(rows.first);
  }

  Future<List<Debt>> getByAccount(int accountId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'debts',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Debt.fromMap).toList();
  }

  Future<Debt> insert(Debt d) async {
    final db = await AppDatabase.instance.database;
    final map = d.toMap();
    if (d.id == null) map.remove('id');
    final id = await db.insert('debts', map);
    return Debt(
      id: id,
      direction: d.direction,
      counterparty: d.counterparty,
      totalCents: d.totalCents,
      remainingCents: d.remainingCents ?? d.totalCents,
      accountId: d.accountId,
      date: d.date,
      note: d.note,
      status: d.status,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
    );
  }

  Future<void> update(Debt d) async {
    final db = await AppDatabase.instance.database;
    await db.update('debts', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('debt_repayments', where: 'debt_id = ?', whereArgs: [id]);
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('debt_repayments');
    await db.delete('debts');
  }

  /// 还款：写一条还款记录，扣减剩余未还；还清则置为 cleared。事务包裹。
  Future<void> repay(Debt debt, DebtRepayment repayment) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.insert('debt_repayments', repayment.toMap()..remove('id'));
      final remaining = debt.remainingCents ?? debt.totalCents;
      final newRemaining = remaining - repayment.amountCents;
      await txn.update(
        'debts',
        {
          'remaining_cents': newRemaining < 0 ? 0 : newRemaining,
          'status': newRemaining <= 0 ? DebtStatus.cleared.name : DebtStatus.open.name,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [debt.id],
      );
    });
  }

  Future<List<DebtRepayment>> getRepayments(int debtId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'debt_repayments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(DebtRepayment.fromMap).toList();
  }

  /// 所有还款记录（备份用）。
  Future<List<DebtRepayment>> getAllRepayments() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('debt_repayments', orderBy: 'id');
    return rows.map(DebtRepayment.fromMap).toList();
  }

  /// 某个账户下的还款记录。
  Future<List<DebtRepayment>> getRepaymentsByAccount(int accountId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'debt_repayments',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(DebtRepayment.fromMap).toList();
  }

  /// 直接插入还款记录（恢复备份用，不扣减 remaining）。
  Future<void> insertRepayment(DebtRepayment r) async {
    final db = await AppDatabase.instance.database;
    await db.insert('debt_repayments', r.toMap()..remove('id'));
  }
}
