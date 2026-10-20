import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/models.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'jucai.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        sortOrder INTEGER NOT NULL
      )
    ''');
    await createAccountTables(db);
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        account_id INTEGER,
        date TEXT NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');
    await createDebtTagTables(db);
    await createPlanTable(db);
    await _seedDefaultCategories(db);
    await _seedDefaultAccounts(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _backupV1(db);
      await migrateV1toV2(db);
    }
    if (oldVersion < 3) {
      await createDebtTagTables(db);
    }
    if (oldVersion < 4) {
      await createPlanTable(db);
    }
  }

  /// 迁移前先把 v1 数据库文件复制一份，迁移失败时数据可回退。
  Future<void> _backupV1(Database db) async {
    try {
      final src = File(db.path);
      if (await src.exists()) {
        await src.copy('${db.path}.v1.bak');
      }
    } catch (_) {
      // 备份失败不阻塞迁移
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final batch = db.batch();
    for (final c in defaultCategories()) {
      batch.insert('categories', c.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedDefaultAccounts(Database db) async {
    final batch = db.batch();
    for (final a in defaultAccounts()) {
      batch.insert('accounts', a.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }
}

/// 创建账户相关新表（accounts / transfers / budgets）。
Future<void> createAccountTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      icon TEXT NOT NULL,
      color INTEGER NOT NULL,
      initial_balance_cents INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE transfers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      from_account_id INTEGER NOT NULL,
      to_account_id INTEGER NOT NULL,
      amount_cents INTEGER NOT NULL,
      fee_cents INTEGER NOT NULL DEFAULT 0,
      date TEXT NOT NULL,
      note TEXT,
      FOREIGN KEY (from_account_id) REFERENCES accounts(id),
      FOREIGN KEY (to_account_id) REFERENCES accounts(id)
    )
  ''');
  await db.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER,
      amount_cents INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories(id)
    )
  ''');
}

/// 创建二期表：debts / debt_repayments / tags / transaction_tags。
Future<void> createDebtTagTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE debts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      direction TEXT NOT NULL,
      counterparty TEXT NOT NULL,
      total_cents INTEGER NOT NULL,
      remaining_cents INTEGER NOT NULL DEFAULT 0,
      account_id INTEGER,
      date TEXT NOT NULL,
      note TEXT,
      status TEXT NOT NULL DEFAULT 'open',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (account_id) REFERENCES accounts(id)
    )
  ''');
  await db.execute('''
    CREATE TABLE debt_repayments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      debt_id INTEGER NOT NULL,
      amount_cents INTEGER NOT NULL,
      date TEXT NOT NULL,
      account_id INTEGER,
      note TEXT,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (debt_id) REFERENCES debts(id),
      FOREIGN KEY (account_id) REFERENCES accounts(id)
    )
  ''');
  await db.execute('''
    CREATE TABLE tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      color INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE transaction_tags (
      transaction_id INTEGER NOT NULL,
      tag_id INTEGER NOT NULL,
      PRIMARY KEY (transaction_id, tag_id),
      FOREIGN KEY (transaction_id) REFERENCES transactions(id),
      FOREIGN KEY (tag_id) REFERENCES tags(id)
    )
  ''');
}

/// 创建周期账表：periodic_plans。
Future<void> createPlanTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE periodic_plans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      amount_cents INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      account_id INTEGER,
      period TEXT NOT NULL,
      day INTEGER NOT NULL,
      month INTEGER,
      note TEXT,
      enabled INTEGER NOT NULL DEFAULT 1,
      last_run_date TEXT,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories(id),
      FOREIGN KEY (account_id) REFERENCES accounts(id)
    )
  ''');
}

/// v1 -> v2：建账户表，把 transactions.account 文本迁移为 account_id，建转账/预算表。
/// 全程事务包裹，任一失败整体回滚。
Future<void> migrateV1toV2(Database db) async {
  await db.transaction((txn) async {
    await createAccountTables(txn);

    for (final a in defaultAccounts()) {
      await txn.insert('accounts', a.toMap()..remove('id'));
    }

    final rows = await txn.rawQuery('SELECT DISTINCT account FROM transactions');
    final texts = <String>[];
    for (final r in rows) {
      final s = (r['account'] as String?)?.trim();
      if (s != null && s.isNotEmpty && !texts.contains(s)) texts.add(s);
    }

    final existing = await txn.query('accounts');
    final nameToId = <String, int>{
      for (final e in existing) e['name'] as String: e['id'] as int,
    };

    for (final text in texts) {
      if (nameToId.containsKey(text)) continue;
      final id = await txn.insert(
        'accounts',
        Account(
          name: text,
          type: AccountType.other,
          icon: 'account_balance',
          color: 0xFF90A4AE,
          sortOrder: 100,
        ).toMap()..remove('id'),
      );
      nameToId[text] = id;
    }

    await txn.execute('ALTER TABLE transactions ADD COLUMN account_id INTEGER');
    for (final text in texts) {
      await txn.update(
        'transactions',
        {'account_id': nameToId[text]},
        where: 'account = ?',
        whereArgs: [text],
      );
    }
    final cashId = nameToId['现金'];
    if (cashId != null) {
      await txn.update('transactions', {'account_id': cashId}, where: 'account_id IS NULL');
    }
  });
}
