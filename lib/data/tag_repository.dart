import '../models/tag.dart';
import 'database.dart';

class TagRepository {
  Future<List<Tag>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tags', orderBy: 'created_at, id');
    return rows.map(Tag.fromMap).toList();
  }

  Future<Tag> insert(Tag t) async {
    final db = await AppDatabase.instance.database;
    final map = t.toMap();
    if (t.id == null) map.remove('id');
    final id = await db.insert('tags', map);
    return Tag(id: id, name: t.name, color: t.color, createdAt: t.createdAt);
  }

  Future<void> update(Tag t) async {
    final db = await AppDatabase.instance.database;
    await db.update('tags', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('transaction_tags', where: 'tag_id = ?', whereArgs: [id]);
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('transaction_tags');
    await db.delete('tags');
  }

  /// 某条流水关联的标签。
  Future<List<Tag>> tagsForTransaction(int transactionId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT t.* FROM tags t '
      'JOIN transaction_tags tt ON tt.tag_id = t.id '
      'WHERE tt.transaction_id = ? ORDER BY t.id',
      [transactionId],
    );
    return rows.map(Tag.fromMap).toList();
  }

  /// 覆盖式设置某条流水的标签。
  Future<void> setTagsForTransaction(int transactionId, List<int> tagIds) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.delete('transaction_tags', where: 'transaction_id = ?', whereArgs: [transactionId]);
      for (final tagId in tagIds) {
        await txn.insert('transaction_tags', {'transaction_id': transactionId, 'tag_id': tagId});
      }
    });
  }

  /// 所有流水-标签关联（备份用）。
  Future<List<Map<String, int>>> getAllLinks() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('transaction_tags');
    return rows
        .map((r) => {
              'transaction_id': r['transaction_id'] as int,
              'tag_id': r['tag_id'] as int,
            })
        .toList();
  }

  /// 批量写入流水-标签关联（恢复备份用）。
  Future<void> insertLinks(List<Map<String, int>> links) async {
    final db = await AppDatabase.instance.database;
    for (final link in links) {
      await db.insert('transaction_tags', link);
    }
  }
}
