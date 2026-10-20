enum TxType { income, expense }

class Category {
  final int? id;
  final String name;
  final TxType type;
  final String icon;
  final int color;
  final int sortOrder;
  final int? parentId;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.sortOrder,
    this.parentId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'icon': icon,
        'color': color,
        'sortOrder': sortOrder,
        'parent_id': parentId,
      };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: TxType.values.byName(m['type'] as String),
        icon: m['icon'] as String,
        color: m['color'] as int,
        sortOrder: m['sortOrder'] as int,
        parentId: m['parent_id'] as int?,
      );
}

class Transaction {
  final int? id;
  final TxType type;
  final int amountCents;
  final int categoryId;
  final String date; // yyyy-MM-dd
  final String? time; // HH:mm，可为空
  final String? note;
  final int? accountId;
  final int createdAt;
  final int updatedAt;

  const Transaction({
    this.id,
    required this.type,
    required this.amountCents,
    required this.categoryId,
    required this.date,
    this.time,
    this.note,
    this.accountId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'amount_cents': amountCents,
        'category_id': categoryId,
        'date': date,
        'time': time,
        'note': note,
        'account_id': accountId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
        id: m['id'] as int?,
        type: TxType.values.byName(m['type'] as String),
        amountCents: m['amount_cents'] as int,
        categoryId: m['category_id'] as int,
        date: m['date'] as String,
        time: m['time'] as String?,
        note: m['note'] as String?,
        accountId: m['account_id'] as int?,
        createdAt: m['created_at'] as int,
        updatedAt: m['updated_at'] as int,
      );
}

List<Category> defaultCategories() {
  return const [
    Category(name: '餐饮', type: TxType.expense, icon: 'restaurant', color: 0xFFE57373, sortOrder: 1),
    Category(name: '交通', type: TxType.expense, icon: 'directions_bus', color: 0xFF64B5F6, sortOrder: 2),
    Category(name: '购物', type: TxType.expense, icon: 'shopping_cart', color: 0xFFBA68C8, sortOrder: 3),
    Category(name: '居住', type: TxType.expense, icon: 'home', color: 0xFF4DB6AC, sortOrder: 4),
    Category(name: '娱乐', type: TxType.expense, icon: 'sports_esports', color: 0xFFFFB74D, sortOrder: 5),
    Category(name: '医疗', type: TxType.expense, icon: 'local_hospital', color: 0xFF81C784, sortOrder: 6),
    Category(name: '人情', type: TxType.expense, icon: 'favorite', color: 0xFFF06292, sortOrder: 7),
    Category(name: '其他', type: TxType.expense, icon: 'more_horiz', color: 0xFF90A4AE, sortOrder: 8),
    Category(name: '工资', type: TxType.income, icon: 'payments', color: 0xFF43A047, sortOrder: 1),
    Category(name: '奖金', type: TxType.income, icon: 'card_giftcard', color: 0xFF66BB6A, sortOrder: 2),
    Category(name: '理财', type: TxType.income, icon: 'trending_up', color: 0xFF26A69A, sortOrder: 3),
    Category(name: '兼职', type: TxType.income, icon: 'work', color: 0xFF29B6F6, sortOrder: 4),
    Category(name: '其他', type: TxType.income, icon: 'more_horiz', color: 0xFF90A4AE, sortOrder: 5),
  ];
}

/// 支出大类目下的子类清单。key 为大类名，value 为其子类名（按顺序）。
Map<String, List<String>> expenseSubCategories() {
  return const {
    '餐饮': ['早餐', '午餐', '晚餐', '零食', '饮品', '外卖'],
    '交通': ['公交', '地铁', '打车', '加油', '停车', '火车飞机', '保险', '高速', '维修', '保养'],
    '购物': ['日用品', '服饰', '数码', '美妆', '母婴'],
    '居住': ['房租', '水电燃气', '物业', '维修', '宽带'],
    '娱乐': ['电影', '游戏', 'KTV', '旅游', '运动'],
    '医疗': ['药品', '门诊', '住院', '体检'],
    '人情': ['请客', '红包', '礼物', '随份子'],
  };
}
