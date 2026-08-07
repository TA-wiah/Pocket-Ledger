import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/report_service.dart';
import 'transaction_provider.dart';

final overallSummaryProvider = Provider<FinancialSummary>((ref) {
  final all = ref.watch(transactionProvider);
  return ReportService.summarize(all);
});

final todaySummaryProvider = Provider<FinancialSummary>((ref) {
  final all = ref.watch(transactionProvider);
  return ReportService.summarize(ReportService.today(all));
});

final monthSummaryProvider = Provider<FinancialSummary>((ref) {
  final all = ref.watch(transactionProvider);
  return ReportService.summarize(ReportService.thisMonth(all));
});

final weekSummaryProvider = Provider<FinancialSummary>((ref) {
  final all = ref.watch(transactionProvider);
  return ReportService.summarize(ReportService.thisWeek(all));
});

final yearSummaryProvider = Provider<FinancialSummary>((ref) {
  final all = ref.watch(transactionProvider);
  return ReportService.summarize(ReportService.thisYear(all));
});

enum ReportPeriod { daily, weekly, monthly, yearly }

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) => ReportPeriod.monthly);

final periodSummaryProvider = Provider<FinancialSummary>((ref) {
  final all = ref.watch(transactionProvider);
  final period = ref.watch(reportPeriodProvider);
  switch (period) {
    case ReportPeriod.daily:
      return ReportService.summarize(ReportService.today(all));
    case ReportPeriod.weekly:
      return ReportService.summarize(ReportService.thisWeek(all));
    case ReportPeriod.monthly:
      return ReportService.summarize(ReportService.thisMonth(all));
    case ReportPeriod.yearly:
      return ReportService.summarize(ReportService.thisYear(all));
  }
});
