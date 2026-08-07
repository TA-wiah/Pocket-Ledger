import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../services/hive_service.dart';

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionNotifier() : super(_loadSorted());

  static List<TransactionModel> _loadSorted() {
    final list = HiveService.transactionsBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void _refresh() => state = _loadSorted();

  Future<void> addTransaction({
    required String title,
    String description = '',
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    String notes = '',
    TransactionStatus status = TransactionStatus.completed,
    String? personId,
  }) async {
    final transaction = TransactionModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      amount: amount,
      type: type,
      category: category,
      date: date,
      notes: notes,
      status: status,
      personId: personId,
    );
    await HiveService.transactionsBox.put(transaction.id, transaction);
    _refresh();
  }

  Future<void> updateTransaction(TransactionModel updated) async {
    await HiveService.transactionsBox.put(updated.id, updated);
    _refresh();
  }

  Future<void> deleteTransaction(String id) async {
    await HiveService.transactionsBox.delete(id);
    _refresh();
  }

  Future<void> deleteAll() async {
    await HiveService.deleteAllTransactions();
    _refresh();
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
  (ref) => TransactionNotifier(),
);

final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final all = ref.watch(transactionProvider);
  return all.take(10).toList();
});

class TransactionFilter {
  final String query;
  final TransactionType? type;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilter({
    this.query = '',
    this.type,
    this.category,
    this.startDate,
    this.endDate,
  });

  TransactionFilter copyWith({
    String? query,
    TransactionType? type,
    bool clearType = false,
    String? category,
    bool clearCategory = false,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
  }) {
    return TransactionFilter(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      category: clearCategory ? null : (category ?? this.category),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final all = ref.watch(transactionProvider);
  final filter = ref.watch(transactionFilterProvider);

  return all.where((t) {
    if (filter.query.isNotEmpty) {
      final q = filter.query.toLowerCase();
      final matches = t.title.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.amount.toString().contains(q) ||
          t.type.name.toLowerCase().contains(q);
      if (!matches) return false;
    }
    if (filter.type != null && t.type != filter.type) return false;
    if (filter.category != null && t.category != filter.category) return false;
    if (filter.startDate != null && t.date.isBefore(filter.startDate!)) return false;
    if (filter.endDate != null && t.date.isAfter(filter.endDate!)) return false;
    return true;
  }).toList();
});
