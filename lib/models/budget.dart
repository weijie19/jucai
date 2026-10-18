class Budget {
  final int? id;
  final int? categoryId; // null = 月总预算
  final int amountCents;

  const Budget({this.id, this.categoryId, required this.amountCents});

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'amount_cents': amountCents,
      };

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
        id: m['id'] as int?,
        categoryId: m['category_id'] as int?,
        amountCents: m['amount_cents'] as int,
      );
}
