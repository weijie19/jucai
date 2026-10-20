import '../models/models.dart';
import 'database.dart';

class CategoryRepository {
  Future<List<Category>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('categories', orderBy: 'type, sortOrder, id');
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Category>> getByType(TxType type) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'categories',
      where: 'type = ? AND parent_id IS NULL',
      whereArgs: [type.name],
      orderBy: 'sortOrder, id',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Category>> getChildren(int parentId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'categories',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'sortOrder, id',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<Category> insert(Category c) async {
    final db = await AppDatabase.instance.database;
    final map = c.toMap();
    if (c.id == null) map.remove('id');
    final id = await db.insert('categories', map);
    return Category(
      id: id,
      name: c.name,
      type: c.type,
      icon: c.icon,
      color: c.color,
      sortOrder: c.sortOrder,
    );
  }

  Future<void> update(Category c) async {
    final db = await AppDatabase.instance.database;
    await db.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('categories');
  }
}
