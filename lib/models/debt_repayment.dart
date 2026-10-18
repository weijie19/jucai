class DebtRepayment {
  final int? id;
  final int debtId;
  final int amountCents;
  final String date; // yyyy-MM-dd
  final int? accountId;
  final String? note;
  final int createdAt;

  const DebtRepayment({
    this.id,
    required this.debtId,
    required this.amountCents,
    required this.date,
    this.accountId,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'debt_id': debtId,
        'amount_cents': amountCents,
        'date': date,
        'account_id': accountId,
        'note': note,
        'created_at': createdAt,
      };

  factory DebtRepayment.fromMap(Map<String, dynamic> m) => DebtRepayment(
        id: m['id'] as int?,
        debtId: m['debt_id'] as int,
        amountCents: m['amount_cents'] as int,
        date: m['date'] as String,
        accountId: m['account_id'] as int?,
        note: m['note'] as String?,
        createdAt: m['created_at'] as int,
      );
}
