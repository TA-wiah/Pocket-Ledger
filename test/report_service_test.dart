import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/utils/date_utils.dart';
import 'package:pocket_ledger/models/transaction_model.dart';
import 'package:pocket_ledger/services/report_service.dart';

TransactionModel _tx({
  required double amount,
  required TransactionType type,
  required DateTime date,
  String category = 'General',
  String id = '',
}) {
  return TransactionModel(
    id: id.isEmpty ? '${date.millisecondsSinceEpoch}-$amount-$type' : id,
    title: 'Test',
    amount: amount,
    type: type,
    category: category,
    date: date,
  );
}

void main() {
  group('ReportService.summarize', () {
    test('computes revenue, expenses, profit, loss, balance correctly', () {
      final now = DateTime.now();
      final txs = [
        _tx(amount: 100, type: TransactionType.income, date: now),
        _tx(amount: 40, type: TransactionType.expense, date: now),
      ];
      final summary = ReportService.summarize(txs);
      expect(summary.revenue, 100);
      expect(summary.expenses, 40);
      expect(summary.profit, 60);
      expect(summary.loss, 0);
      expect(summary.balance, 60);
      expect(summary.transactionCount, 2);
    });

    test('reports loss (not negative profit) when expenses exceed revenue', () {
      final now = DateTime.now();
      final txs = [
        _tx(amount: 30, type: TransactionType.income, date: now),
        _tx(amount: 100, type: TransactionType.expense, date: now),
      ];
      final summary = ReportService.summarize(txs);
      expect(summary.profit, 0);
      expect(summary.loss, 70);
      expect(summary.balance, -70);
    });

    test('empty list summarizes to all zeros', () {
      final summary = ReportService.summarize([]);
      expect(summary.revenue, 0);
      expect(summary.expenses, 0);
      expect(summary.profit, 0);
      expect(summary.loss, 0);
      expect(summary.balance, 0);
      expect(summary.transactionCount, 0);
    });
  });

  group('period filters include the full period, not just up-to-now', () {
    test('thisMonth includes a transaction dated later this month (future-dated entry)', () {
      final now = DateTime.now();
      final lastDayOfMonth = AppDateUtils.endOfMonth(now);
      // Skip this scenario entirely if "now" already IS the last day of the month.
      if (AppDateUtils.isSameDay(now, lastDayOfMonth)) return;

      final futureThisMonth = _tx(
        amount: 50,
        type: TransactionType.expense,
        date: DateTime(lastDayOfMonth.year, lastDayOfMonth.month, lastDayOfMonth.day, 10),
      );
      final result = ReportService.thisMonth([futureThisMonth]);
      expect(result, contains(futureThisMonth));
    });

    test('thisMonth excludes a transaction from a different month', () {
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 15);
      final tx = _tx(amount: 50, type: TransactionType.expense, date: nextMonth);
      final result = ReportService.thisMonth([tx]);
      expect(result, isNot(contains(tx)));
    });

    test('thisWeek includes every day of the current week regardless of time-of-day', () {
      final now = DateTime.now();
      final start = AppDateUtils.startOfWeek(now);
      final end = AppDateUtils.endOfWeek(now);
      expect(end.difference(start).inDays, 6);

      final firstDayTx = _tx(amount: 10, type: TransactionType.income, date: start);
      final lastDayTx = _tx(
        amount: 20,
        type: TransactionType.income,
        date: DateTime(end.year, end.month, end.day, 23, 0),
        id: 'last-day',
      );
      final result = ReportService.thisWeek([firstDayTx, lastDayTx]);
      expect(result, containsAll([firstDayTx, lastDayTx]));
    });

    test('thisYear includes a transaction dated later this year', () {
      final now = DateTime.now();
      if (now.month == 12 && now.day == 31) return;
      final laterThisYear = _tx(
        amount: 75,
        type: TransactionType.income,
        date: DateTime(now.year, 12, 31),
      );
      final result = ReportService.thisYear([laterThisYear]);
      expect(result, contains(laterThisYear));
    });
  });

  group('ReportService.today / filterByDay', () {
    test('matches only same calendar day regardless of time', () {
      final now = DateTime.now();
      final earlyToday = DateTime(now.year, now.month, now.day, 0, 1);
      final lateToday = DateTime(now.year, now.month, now.day, 23, 59);
      final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

      final txs = [
        _tx(amount: 5, type: TransactionType.income, date: earlyToday, id: 'a'),
        _tx(amount: 5, type: TransactionType.income, date: lateToday, id: 'b'),
        _tx(amount: 5, type: TransactionType.income, date: tomorrow, id: 'c'),
      ];
      final result = ReportService.today(txs);
      expect(result.map((t) => t.id), containsAll(['a', 'b']));
      expect(result.map((t) => t.id), isNot(contains('c')));
    });
  });

  group('ReportService.categoryBreakdown', () {
    test('groups by category and percentages sum to 100', () {
      final now = DateTime.now();
      final txs = [
        _tx(amount: 60, type: TransactionType.expense, date: now, category: 'Food', id: '1'),
        _tx(amount: 40, type: TransactionType.expense, date: now, category: 'Transport', id: '2'),
        _tx(amount: 20, type: TransactionType.income, date: now, category: 'Salary', id: '3'),
      ];
      final breakdown = ReportService.categoryBreakdown(txs, TransactionType.expense);
      expect(breakdown.length, 2);
      final food = breakdown.firstWhere((e) => e.category == 'Food');
      final transport = breakdown.firstWhere((e) => e.category == 'Transport');
      expect(food.amount, 60);
      expect(transport.amount, 40);
      expect(food.percentage + transport.percentage, closeTo(100, 0.001));
      // Sorted descending by amount.
      expect(breakdown.first.category, 'Food');
    });

    test('empty input returns empty breakdown without dividing by zero', () {
      final breakdown = ReportService.categoryBreakdown([], TransactionType.expense);
      expect(breakdown, isEmpty);
    });
  });

  group('ReportService.monthlyTrend', () {
    test('returns entries oldest-to-newest ending with the current month', () {
      final now = DateTime.now();
      final trend = ReportService.monthlyTrend([], 3);
      expect(trend.length, 3);
      expect(trend.last.key.year, now.year);
      expect(trend.last.key.month, now.month);
    });

    test('places a transaction in the correct month bucket', () {
      final now = DateTime.now();
      final twoMonthsAgo = DateTime(now.year, now.month - 2, 10);
      final tx = _tx(amount: 15, type: TransactionType.income, date: twoMonthsAgo);
      final trend = ReportService.monthlyTrend([tx], 3);
      expect(trend.first.value.revenue, 15);
      expect(trend[1].value.revenue, 0);
      expect(trend.last.value.revenue, 0);
    });
  });

  group('ReportService.dailyTrend', () {
    test('returns entries oldest-to-newest ending with today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final trend = ReportService.dailyTrend([], 7);
      expect(trend.length, 7);
      expect(trend.last.key, today);
    });
  });

  group('AppDateUtils', () {
    test('startOfWeek returns a Monday', () {
      final anyDate = DateTime(2026, 8, 8); // a Saturday
      final start = AppDateUtils.startOfWeek(anyDate);
      expect(start.weekday, DateTime.monday);
    });

    test('endOfWeek is 6 days after startOfWeek, same week', () {
      final anyDate = DateTime(2026, 8, 8);
      final start = AppDateUtils.startOfWeek(anyDate);
      final end = AppDateUtils.endOfWeek(anyDate);
      expect(end.difference(start).inDays, 6);
      expect(end.weekday, DateTime.sunday);
    });

    test('endOfMonth lands on the last calendar day of the month', () {
      final feb2026 = DateTime(2026, 2, 10);
      final end = AppDateUtils.endOfMonth(feb2026);
      expect(end.day, 28); // 2026 is not a leap year
      expect(end.month, 2);
    });

    test('endOfMonth handles December correctly (year rollover)', () {
      final dec = DateTime(2026, 12, 5);
      final end = AppDateUtils.endOfMonth(dec);
      expect(end.year, 2026);
      expect(end.month, 12);
      expect(end.day, 31);
    });
  });
}
