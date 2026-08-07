import '../models/transaction_model.dart';
import '../core/utils/date_utils.dart';

class FinancialSummary {
  final double revenue;
  final double expenses;
  final double profit;
  final double loss;
  final double balance;
  final int transactionCount;

  const FinancialSummary({
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.loss,
    required this.balance,
    required this.transactionCount,
  });

  static const empty = FinancialSummary(
    revenue: 0,
    expenses: 0,
    profit: 0,
    loss: 0,
    balance: 0,
    transactionCount: 0,
  );
}

class CategoryBreakdownEntry {
  final String category;
  final double amount;
  final double percentage;

  const CategoryBreakdownEntry({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class ReportService {
  ReportService._();

  static double totalRevenue(List<TransactionModel> transactions) => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  static double totalExpenses(List<TransactionModel> transactions) => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  static FinancialSummary summarize(List<TransactionModel> transactions) {
    final revenue = totalRevenue(transactions);
    final expenses = totalExpenses(transactions);
    final profit = revenue - expenses;
    return FinancialSummary(
      revenue: revenue,
      expenses: expenses,
      profit: profit > 0 ? profit : 0,
      loss: profit < 0 ? profit.abs() : 0,
      balance: revenue - expenses,
      transactionCount: transactions.length,
    );
  }

  static List<TransactionModel> filterByDay(List<TransactionModel> all, DateTime day) =>
      all.where((t) => AppDateUtils.isSameDay(t.date, day)).toList();

  static List<TransactionModel> filterByRange(
    List<TransactionModel> all,
    DateTime start,
    DateTime end,
  ) =>
      all.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();

  static List<TransactionModel> today(List<TransactionModel> all) =>
      filterByDay(all, DateTime.now());

  static List<TransactionModel> yesterday(List<TransactionModel> all) =>
      filterByDay(all, DateTime.now().subtract(const Duration(days: 1)));

  static List<TransactionModel> thisWeek(List<TransactionModel> all) {
    final start = AppDateUtils.startOfWeek(DateTime.now());
    return filterByRange(all, start, DateTime.now());
  }

  static List<TransactionModel> thisMonth(List<TransactionModel> all) {
    final now = DateTime.now();
    final start = AppDateUtils.startOfMonth(now);
    return filterByRange(all, start, now);
  }

  static List<TransactionModel> thisYear(List<TransactionModel> all) {
    final now = DateTime.now();
    final start = AppDateUtils.startOfYear(now);
    return filterByRange(all, start, now);
  }

  static List<TransactionModel> lastMonth(List<TransactionModel> all) {
    final now = DateTime.now();
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final lastMonthEnd = firstOfThisMonth.subtract(const Duration(days: 1));
    final lastMonthStart = DateTime(lastMonthEnd.year, lastMonthEnd.month, 1);
    return filterByRange(all, lastMonthStart, lastMonthEnd);
  }

  static double highestExpense(List<TransactionModel> all) {
    final expenses = all.where((t) => t.type == TransactionType.expense);
    if (expenses.isEmpty) return 0;
    return expenses.map((t) => t.amount).reduce((a, b) => a > b ? a : b);
  }

  static double highestIncome(List<TransactionModel> all) {
    final income = all.where((t) => t.type == TransactionType.income);
    if (income.isEmpty) return 0;
    return income.map((t) => t.amount).reduce((a, b) => a > b ? a : b);
  }

  static double averageDailyIncome(List<TransactionModel> all) {
    final monthTx = thisMonth(all).where((t) => t.type == TransactionType.income);
    final total = monthTx.fold(0.0, (sum, t) => sum + t.amount);
    final day = DateTime.now().day;
    return day == 0 ? 0 : total / day;
  }

  static double averageDailyExpense(List<TransactionModel> all) {
    final monthTx = thisMonth(all).where((t) => t.type == TransactionType.expense);
    final total = monthTx.fold(0.0, (sum, t) => sum + t.amount);
    final day = DateTime.now().day;
    return day == 0 ? 0 : total / day;
  }

  static List<CategoryBreakdownEntry> categoryBreakdown(
    List<TransactionModel> all,
    TransactionType type,
  ) {
    final filtered = all.where((t) => t.type == type);
    final total = filtered.fold(0.0, (sum, t) => sum + t.amount);
    final Map<String, double> grouped = {};
    for (final t in filtered) {
      grouped[t.category] = (grouped[t.category] ?? 0) + t.amount;
    }
    final entries = grouped.entries
        .map((e) => CategoryBreakdownEntry(
              category: e.key,
              amount: e.value,
              percentage: total == 0 ? 0 : (e.value / total) * 100,
            ))
        .toList();
    entries.sort((a, b) => b.amount.compareTo(a.amount));
    return entries;
  }

  static List<MapEntry<DateTime, FinancialSummary>> dailyTrend(
    List<TransactionModel> all,
    int days,
  ) {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, FinancialSummary>>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayTx = filterByDay(all, day);
      result.add(MapEntry(day, summarize(dayTx)));
    }
    return result;
  }

  static List<MapEntry<DateTime, FinancialSummary>> monthlyTrend(
    List<TransactionModel> all,
    int months,
  ) {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, FinancialSummary>>[];
    for (int i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final start = DateTime(monthDate.year, monthDate.month, 1);
      final end = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
      final monthTx = filterByRange(all, start, end);
      result.add(MapEntry(start, summarize(monthTx)));
    }
    return result;
  }
}
