import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/models.dart';
import '../services/amount.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _MonthPoint {
  final String label; // 如 "6月"
  final double expense; // 元
  final double income; // 元
  _MonthPoint(this.label, this.expense, this.income);
}

class _CategorySlice {
  final String name;
  final int color;
  final double cents; // 元
  final double percent;
  _CategorySlice(this.name, this.color, this.cents, this.percent);
}

class _ReportScreenState extends State<ReportScreen> {
  List<_MonthPoint> _months = [];
  List<_CategorySlice> _slices = [];
  int _monthExpense = 0;
  int _monthIncome = 0;
  bool _loading = true;
  TxType _pieType = TxType.expense;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _setPieType(TxType t) {
    setState(() => _pieType = t);
    _loadPie();
  }

  Future<void> _reload() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();

    // 近 6 个月（含本月）
    final first = DateTime(now.year, now.month - 5, 1);
    final startKey = '${first.year}-${first.month.toString().padLeft(2, '0')}';
    final trendRows = await db.rawQuery(
      'SELECT substr(date, 1, 7) AS ym, type, SUM(amount_cents) AS s '
      'FROM transactions WHERE date >= ? GROUP BY ym, type',
      ['$startKey-01'],
    );
    final trend = <String, Map<String, int>>{};
    for (final r in trendRows) {
      final ym = r['ym'] as String;
      final type = r['type'] as String;
      final s = (r['s'] as num).toInt();
      trend.putIfAbsent(ym, () => {'expense': 0, 'income': 0});
      trend[ym]![type] = s;
    }

    final months = <_MonthPoint>[];
    for (var i = 0; i < 6; i++) {
      final d = DateTime(now.year, now.month - 5 + i, 1);
      final ym = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      final m = trend[ym] ?? {'expense': 0, 'income': 0};
      months.add(_MonthPoint(
        '${d.month}月',
        (m['expense'] ?? 0) / 100,
        (m['income'] ?? 0) / 100,
      ));
    }

    // 当月收支汇总
    final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final next = now.month == 12
        ? '${now.year + 1}-01-01'
        : '${now.year}-${(now.month + 1).toString().padLeft(2, '0')}-01';
    final monthExpense = await _sumMonth(db, 'expense', monthStart, next);
    final monthIncome = await _sumMonth(db, 'income', monthStart, next);

    if (!mounted) return;
    setState(() {
      _months = months;
      _monthExpense = monthExpense;
      _monthIncome = monthIncome;
      _loading = false;
    });

    await _loadPie();
  }

  Future<void> _loadPie() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final next = now.month == 12
        ? '${now.year + 1}-01-01'
        : '${now.year}-${(now.month + 1).toString().padLeft(2, '0')}-01';
    final catRows = await db.rawQuery(
      'SELECT c.name AS name, c.color AS color, SUM(t.amount_cents) AS s '
      'FROM transactions t JOIN categories c ON t.category_id = c.id '
      'WHERE t.type = ? AND t.date >= ? AND t.date < ? '
      'GROUP BY t.category_id ORDER BY s DESC',
      [_pieType.name, monthStart, next],
    );
    var totalCents = 0;
    for (final r in catRows) {
      totalCents += (r['s'] as num).toInt();
    }
    final slices = <_CategorySlice>[];
    for (final r in catRows) {
      final cents = (r['s'] as num).toInt();
      slices.add(_CategorySlice(
        r['name'] as String,
        r['color'] as int,
        cents / 100,
        totalCents == 0 ? 0 : cents / totalCents * 100,
      ));
    }
    if (!mounted) return;
    setState(() => _slices = slices);
  }

  Future<int> _sumMonth(dynamic db, String type, String start, String next) async {
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_cents),0) AS s FROM transactions '
      'WHERE type = ? AND date >= ? AND date < ?',
      [type, start, next],
    );
    return (rows.first['s'] as num).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('报表')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummary(),
                const SizedBox(height: 24),
                Text('近 6 个月收支趋势', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildTrendChart(),
                const SizedBox(height: 24),
                Text(
                  _pieType == TxType.expense ? '本月分类支出占比' : '本月分类收入占比',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<TxType>(
                  segments: const [
                    ButtonSegment(value: TxType.expense, label: Text('支出')),
                    ButtonSegment(value: TxType.income, label: Text('收入')),
                  ],
                  selected: {_pieType},
                  onSelectionChanged: (s) => _setPieType(s.first),
                ),
                const SizedBox(height: 8),
                _buildPieChart(),
              ],
            ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        _summaryItem('本月支出', _monthExpense, Colors.red),
        _summaryItem('本月收入', _monthIncome, Colors.green),
        _summaryItem('本月结余', _monthIncome - _monthExpense, Colors.blue),
      ],
    );
  }

  Widget _summaryItem(String label, int cents, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text('¥${formatCents(cents)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final expenseSpots = <FlSpot>[];
    final incomeSpots = <FlSpot>[];
    for (var i = 0; i < _months.length; i++) {
      expenseSpots.add(FlSpot(i.toDouble(), _months[i].expense));
      incomeSpots.add(FlSpot(i.toDouble(), _months[i].income));
    }
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: expenseSpots,
              color: Colors.red,
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
            LineChartBarData(
              spots: incomeSpots,
              color: Colors.green,
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _months.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_months[i].label, style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: true),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_slices.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(_pieType == TxType.expense ? '本月暂无支出' : '本月暂无收入')),
      );
    }
    return SizedBox(
      height: 240,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: _slices
                    .map((s) => PieChartSectionData(
                          value: s.cents,
                          color: Color(s.color),
                          title: s.percent >= 5 ? '${s.percent.toStringAsFixed(0)}%' : '',
                          radius: 60,
                          titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
                        ))
                    .toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _slices.take(8).map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(s.color), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(s.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                        Text('${s.percent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
