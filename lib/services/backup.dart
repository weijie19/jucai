import 'dart:convert';
import '../models/models.dart';

class BackupData {
  final List<Category> categories;
  final List<Transaction> transactions;
  const BackupData({required this.categories, required this.transactions});
}

String encodeBackup(BackupData data) {
  final map = {
    'version': 1,
    'exported_at': DateTime.now().millisecondsSinceEpoch,
    'categories': data.categories.map((c) => c.toMap()).toList(),
    'transactions': data.transactions.map((t) => t.toMap()).toList(),
  };
  return jsonEncode(map);
}

BackupData decodeBackup(String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  final cats = (map['categories'] as List)
      .map((e) => Category.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();
  final txs = (map['transactions'] as List)
      .map((e) => Transaction.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();
  return BackupData(categories: cats, transactions: txs);
}
