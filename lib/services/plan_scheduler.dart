import '../models/periodic_plan.dart';

/// 计算周期账计划的下一次执行日期。
/// 返回 null 表示无法计算（数据异常）。
DateTime? nextRunDate(PeriodicPlan plan, DateTime from) {
  switch (plan.period) {
    case 'monthly':
      final d = plan.day.clamp(1, 28);
      var candidate = DateTime(from.year, from.month, d);
      if (candidate.isBefore(from) || candidate == from) {
        candidate = DateTime(from.year, from.month + 1, d);
      }
      return candidate;
    case 'weekly':
      // 1=周一..7=周日
      final target = plan.day.clamp(1, 7);
      final delta = (target - from.weekday) % 7;
      var candidate = DateTime(from.year, from.month, from.day + (delta < 0 ? delta + 7 : delta));
      if (candidate.isBefore(from) || candidate == from) {
        candidate = candidate.add(const Duration(days: 7));
      }
      return candidate;
    case 'yearly':
      final m = (plan.month ?? 1).clamp(1, 12);
      final d = plan.day.clamp(1, 28);
      var candidate = DateTime(from.year, m, d);
      if (candidate.isBefore(from) || candidate == from) {
        candidate = DateTime(from.year + 1, m, d);
      }
      return candidate;
    default:
      return null;
  }
}
