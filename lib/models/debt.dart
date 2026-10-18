enum DebtDirection { lend, borrow }

enum DebtStatus { open, cleared }

class Debt {
  final int? id;
  final DebtDirection direction;
  final String counterparty;
  final int totalCents;
  final int? remainingCents;
  final int? accountId;
  final String date; // yyyy-MM-dd
  final String? note;
  final DebtStatus status;
  final int createdAt;
  final int updatedAt;

  const Debt({
    this.id,
    required this.direction,
    required this.counterparty,
    required this.totalCents,
    this.remainingCents,
    this.accountId,
    required this.date,
    this.note,
    this.status = DebtStatus.open,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'direction': direction.name,
        'counterparty': counterparty,
        'total_cents': totalCents,
        'remaining_cents': remainingCents ?? totalCents,
        'account_id': accountId,
        'date': date,
        'note': note,
        'status': status.name,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Debt.fromMap(Map<String, dynamic> m) => Debt(
        id: m['id'] as int?,
        direction: DebtDirection.values.byName(m['direction'] as String),
        counterparty: m['counterparty'] as String,
        totalCents: m['total_cents'] as int,
        remainingCents: m['remaining_cents'] as int?,
        accountId: m['account_id'] as int?,
        date: m['date'] as String,
        note: m['note'] as String?,
        status: DebtStatus.values.byName((m['status'] as String?) ?? 'open'),
        createdAt: m['created_at'] as int,
        updatedAt: m['updated_at'] as int,
      );
}
