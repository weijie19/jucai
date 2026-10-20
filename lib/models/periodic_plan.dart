import 'models.dart';

/// 周期账计划（房租、工资、信用卡还款等定期收支）。
class PeriodicPlan {
  final int? id;
  final String name;
  final TxType type;
  final int amountCents;
  final int categoryId;
  final int? accountId;
  final String period; // monthly | weekly | yearly
  final int day; // monthly: 几号(1-31)；weekly: 周几(1=周一..7=周日)；yearly: 日(1-31)
  final int? month; // yearly: 几月(1-12)
  final String? note;
  final bool enabled;
  final String? lastRunDate; // 上次自动入账日期 yyyy-MM-dd
  final int createdAt;

  const PeriodicPlan({
    this.id,
    required this.name,
    required this.type,
    required this.amountCents,
    required this.categoryId,
    this.accountId,
    required this.period,
    required this.day,
    this.month,
    this.note,
    this.enabled = true,
    this.lastRunDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'amount_cents': amountCents,
        'category_id': categoryId,
        'account_id': accountId,
        'period': period,
        'day': day,
        'month': month,
        'note': note,
        'enabled': enabled ? 1 : 0,
        'last_run_date': lastRunDate,
        'created_at': createdAt,
      };

  factory PeriodicPlan.fromMap(Map<String, dynamic> m) => PeriodicPlan(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: TxType.values.byName(m['type'] as String),
        amountCents: m['amount_cents'] as int,
        categoryId: m['category_id'] as int,
        accountId: m['account_id'] as int?,
        period: m['period'] as String,
        day: m['day'] as int,
        month: m['month'] as int?,
        note: m['note'] as String?,
        enabled: (m['enabled'] as int? ?? 1) == 1,
        lastRunDate: m['last_run_date'] as String?,
        createdAt: m['created_at'] as int,
      );

  PeriodicPlan copyWith({bool? enabled, String? lastRunDate}) => PeriodicPlan(
        id: id,
        name: name,
        type: type,
        amountCents: amountCents,
        categoryId: categoryId,
        accountId: accountId,
        period: period,
        day: day,
        month: month,
        note: note,
        enabled: enabled ?? this.enabled,
        lastRunDate: lastRunDate ?? this.lastRunDate,
        createdAt: createdAt,
      );
}
