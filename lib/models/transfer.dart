class Transfer {
  final int? id;
  final int fromAccountId;
  final int toAccountId;
  final int amountCents;
  final int feeCents;
  final String date; // yyyy-MM-dd
  final String? note;

  const Transfer({
    this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amountCents,
    this.feeCents = 0,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
        'amount_cents': amountCents,
        'fee_cents': feeCents,
        'date': date,
        'note': note,
      };

  factory Transfer.fromMap(Map<String, dynamic> m) => Transfer(
        id: m['id'] as int?,
        fromAccountId: m['from_account_id'] as int,
        toAccountId: m['to_account_id'] as int,
        amountCents: m['amount_cents'] as int,
        feeCents: m['fee_cents'] as int? ?? 0,
        date: m['date'] as String,
        note: m['note'] as String?,
      );
}
