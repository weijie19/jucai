import 'dart:convert';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/debt_repayment.dart';
import '../models/models.dart';
import '../models/tag.dart';
import '../models/transfer.dart';

class BackupData {
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Transfer> transfers;
  final List<Budget> budgets;
  final List<Debt> debts;
  final List<DebtRepayment> debtRepayments;
  final List<Tag> tags;
  final List<Map<String, int>> transactionTags;

  const BackupData({
    required this.categories,
    required this.transactions,
    this.accounts = const [],
    this.transfers = const [],
    this.budgets = const [],
    this.debts = const [],
    this.debtRepayments = const [],
    this.tags = const [],
    this.transactionTags = const [],
  });
}

String encodeBackup(BackupData data) {
  final map = {
    'version': 3,
    'exported_at': DateTime.now().millisecondsSinceEpoch,
    'categories': data.categories.map((c) => c.toMap()).toList(),
    'transactions': data.transactions.map((t) => t.toMap()).toList(),
    'accounts': data.accounts.map((a) => a.toMap()).toList(),
    'transfers': data.transfers.map((t) => t.toMap()).toList(),
    'budgets': data.budgets.map((b) => b.toMap()).toList(),
    'debts': data.debts.map((d) => d.toMap()).toList(),
    'debt_repayments': data.debtRepayments.map((r) => r.toMap()).toList(),
    'tags': data.tags.map((t) => t.toMap()).toList(),
    'transaction_tags': data.transactionTags,
  };
  return jsonEncode(map);
}

BackupData decodeBackup(String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  List<T> listOf<T>(String key, T Function(Map<String, dynamic>) fromMap) {
    final raw = map[key] as List? ?? const [];
    return raw.map((e) => fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  return BackupData(
    categories: listOf('categories', Category.fromMap),
    transactions: listOf('transactions', Transaction.fromMap),
    accounts: listOf('accounts', Account.fromMap),
    transfers: listOf('transfers', Transfer.fromMap),
    budgets: listOf('budgets', Budget.fromMap),
    debts: listOf('debts', Debt.fromMap),
    debtRepayments: listOf('debt_repayments', DebtRepayment.fromMap),
    tags: listOf('tags', Tag.fromMap),
    transactionTags: (map['transaction_tags'] as List? ?? const [])
        .map((e) => Map<String, int>.from(e as Map))
        .toList(),
  );
}
