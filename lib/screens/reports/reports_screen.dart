import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/report_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/report_service.dart';
import '../../models/transaction_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(transactionProvider);
    final period = ref.watch(reportPeriodProvider);
    final summary = ref.watch(periodSummaryProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final monthlyTrend = ReportService.monthlyTrend(all, 6);
    final expenseBreakdown = ReportService.categoryBreakdown(all, TransactionType.expense);
    final incomeBreakdown = ReportService.categoryBreakdown(all, TransactionType.income);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<ReportPeriod>(
            segments: const [
              ButtonSegment(value: ReportPeriod.daily, label: Text('Day')),
              ButtonSegment(value: ReportPeriod.weekly, label: Text('Week')),
              ButtonSegment(value: ReportPeriod.monthly, label: Text('Month')),
              ButtonSegment(value: ReportPeriod.yearly, label: Text('Year')),
            ],
            selected: {period},
            onSelectionChanged: (s) =>
                ref.read(reportPeriodProvider.notifier).state = s.first,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _summaryRow(context, 'Revenue', summary.revenue, AppColors.income, symbol),
                const Divider(height: 20),
                _summaryRow(context, 'Expenses', summary.expenses, AppColors.expense, symbol),
                const Divider(height: 20),
                _summaryRow(context, 'Profit', summary.profit, AppColors.income, symbol),
                const Divider(height: 20),
                _summaryRow(context, 'Loss', summary.loss, AppColors.loss, symbol),
                const Divider(height: 20),
                _summaryRow(context, 'Balance', summary.balance, AppColors.primaryBlue, symbol),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('6-Month Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _TrendLineChart(trend: monthlyTrend),
          ),
          const SizedBox(height: 24),
          Text('Expense Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _BreakdownCard(entries: expenseBreakdown, symbol: symbol, baseColor: AppColors.expense),
          const SizedBox(height: 24),
          Text('Income Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _BreakdownCard(entries: incomeBreakdown, symbol: symbol, baseColor: AppColors.income),
          const SizedBox(height: 24),
          Text('Revenue vs Expenses',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _RevenueExpenseBarChart(trend: monthlyTrend),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, double value, Color color, String symbol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            CurrencyFormatter.format(value, symbol: symbol),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final List<CategoryBreakdownEntry> entries;
  final String symbol;
  final Color baseColor;

  const _BreakdownCard({required this.entries, required this.symbol, required this.baseColor});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('No data yet')),
      );
    }

    final colors = _generateShades(baseColor, entries.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  for (int i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].amount,
                      title: '${entries[i].percentage.toStringAsFixed(0)}%',
                      color: colors[i],
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(entries.length, (i) {
            final e = entries[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e.category, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      CurrencyFormatter.format(e.amount, symbol: symbol),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Color> _generateShades(Color base, int count) {
    final hsl = HSLColor.fromColor(base);
    return List.generate(count, (i) {
      final lightness = (hsl.lightness + (i * 0.08)).clamp(0.25, 0.75);
      return hsl.withLightness(lightness).toColor();
    });
  }
}

class _TrendLineChart extends StatelessWidget {
  final List<MapEntry<DateTime, FinancialSummary>> trend;

  const _TrendLineChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormatShort.monthAbbrev(trend[index].key),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (int i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i].value.revenue)],
            isCurved: true,
            color: AppColors.income,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: [for (int i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i].value.expenses)],
            isCurved: true,
            color: AppColors.expense,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _RevenueExpenseBarChart extends StatelessWidget {
  final List<MapEntry<DateTime, FinancialSummary>> trend;

  const _RevenueExpenseBarChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    double maxY = 10;
    for (final entry in trend) {
      if (entry.value.revenue > maxY) maxY = entry.value.revenue;
      if (entry.value.expenses > maxY) maxY = entry.value.expenses;
    }
    maxY *= 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormatShort.monthAbbrev(trend[index].key),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < trend.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: trend[i].value.revenue,
                  color: AppColors.income,
                  width: 8,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: trend[i].value.expenses,
                  color: AppColors.expense,
                  width: 8,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class DateFormatShort {
  static String monthAbbrev(DateTime date) => AppDateUtils.formatMonthYear(date).split(' ').first.substring(0, 3);
}
