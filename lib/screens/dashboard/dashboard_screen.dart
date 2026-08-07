import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/report_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/report_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_model.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_edit_transaction_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(transactionProvider);
    final overall = ref.watch(overallSummaryProvider);
    final today = ref.watch(todaySummaryProvider);
    final month = ref.watch(monthSummaryProvider);
    final recent = ref.watch(recentTransactionsProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final trend = ReportService.dailyTrend(all, 7);

    final cards = <_CardData>[
      _CardData('Total Revenue', overall.revenue, Icons.trending_up, AppColors.income),
      _CardData('Total Expenses', overall.expenses, Icons.trending_down, AppColors.expense),
      _CardData('Total Profit', overall.profit, Icons.savings, AppColors.income),
      _CardData('Total Loss', overall.loss, Icons.money_off, AppColors.loss),
      _CardData('Current Balance', overall.balance, Icons.account_balance_wallet, AppColors.primaryBlue),
      _CardData('Total Transactions', overall.transactionCount.toDouble(), Icons.receipt_long,
          AppColors.emerald,
          isCount: true),
      _CardData('Today\'s Income', today.revenue, Icons.today, AppColors.income),
      _CardData('Today\'s Expenses', today.expenses, Icons.calendar_today, AppColors.expense),
      _CardData('Monthly Revenue', month.revenue, Icons.calendar_month, AppColors.income),
      _CardData('Monthly Expenses', month.expenses, Icons.calendar_view_month, AppColors.expense),
      _CardData('Net Profit', month.profit - month.loss, Icons.stacked_line_chart, AppColors.primaryBlue),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: _QuickAddButton(
                    label: 'Quick Add Income',
                    icon: Icons.add_circle,
                    color: AppColors.income,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditTransactionScreen(
                          initialType: TransactionType.income,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAddButton(
                    label: 'Quick Add Expense',
                    icon: Icons.remove_circle,
                    color: AppColors.expense,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditTransactionScreen(
                          initialType: TransactionType.expense,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, index) {
                final c = cards[index];
                return SummaryCard(
                  label: c.label,
                  value: c.isCount
                      ? c.value.toInt().toString()
                      : CurrencyFormatter.formatCompact(c.value, symbol: symbol),
                  icon: c.icon,
                  color: c.color,
                  animationIndex: index,
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Income vs Expense (Last 7 Days)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _IncomeExpenseBarChart(trend: trend),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No transactions yet')),
              )
            else
              ...recent.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: TransactionTile(
                      transaction: t,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditTransactionScreen(existing: t),
                        ),
                      ),
                      onDelete: () =>
                          ref.read(transactionProvider.notifier).deleteTransaction(t.id),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _CardData {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isCount;

  _CardData(this.label, this.value, this.icon, this.color, {this.isCount = false});
}

class _QuickAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeExpenseBarChart extends StatelessWidget {
  final List<MapEntry<DateTime, FinancialSummary>> trend;

  const _IncomeExpenseBarChart({required this.trend});

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
                    AppDateUtils.formatDayMonth(trend[index].key).split(' ').first,
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
                  width: 7,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: trend[i].value.expenses,
                  color: AppColors.expense,
                  width: 7,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
