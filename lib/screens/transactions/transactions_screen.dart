import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_tile.dart';
import 'add_edit_transaction_screen.dart';

enum _QuickFilter { all, today, yesterday, week, month, year }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _QuickFilter _quickFilter = _QuickFilter.all;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyQuickFilter(_QuickFilter filter) {
    setState(() => _quickFilter = filter);
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;
    switch (filter) {
      case _QuickFilter.all:
        break;
      case _QuickFilter.today:
        start = DateTime(now.year, now.month, now.day);
        end = now;
        break;
      case _QuickFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        start = DateTime(y.year, y.month, y.day);
        end = DateTime(y.year, y.month, y.day, 23, 59, 59);
        break;
      case _QuickFilter.week:
        start = AppDateUtils.startOfWeek(now);
        end = now;
        break;
      case _QuickFilter.month:
        start = AppDateUtils.startOfMonth(now);
        end = now;
        break;
      case _QuickFilter.year:
        start = AppDateUtils.startOfYear(now);
        end = now;
        break;
    }
    final current = ref.read(transactionFilterProvider);
    ref.read(transactionFilterProvider.notifier).state = current.copyWith(
      startDate: start,
      endDate: end,
      clearDates: filter == _QuickFilter.all,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, category, amount...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(transactionFilterProvider.notifier).state =
                              filter.copyWith(query: '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(query: value);
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _quickFilter == _QuickFilter.all,
                  onTap: () => _applyQuickFilter(_QuickFilter.all),
                ),
                _FilterChip(
                  label: 'Today',
                  selected: _quickFilter == _QuickFilter.today,
                  onTap: () => _applyQuickFilter(_QuickFilter.today),
                ),
                _FilterChip(
                  label: 'Yesterday',
                  selected: _quickFilter == _QuickFilter.yesterday,
                  onTap: () => _applyQuickFilter(_QuickFilter.yesterday),
                ),
                _FilterChip(
                  label: 'This Week',
                  selected: _quickFilter == _QuickFilter.week,
                  onTap: () => _applyQuickFilter(_QuickFilter.week),
                ),
                _FilterChip(
                  label: 'This Month',
                  selected: _quickFilter == _QuickFilter.month,
                  onTap: () => _applyQuickFilter(_QuickFilter.month),
                ),
                _FilterChip(
                  label: 'This Year',
                  selected: _quickFilter == _QuickFilter.year,
                  onTap: () => _applyQuickFilter(_QuickFilter.year),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TransactionType?>(
                    initialValue: filter.type,
                    decoration: const InputDecoration(labelText: 'Type', isDense: true),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Types')),
                      DropdownMenuItem(value: TransactionType.income, child: Text('Income')),
                      DropdownMenuItem(value: TransactionType.expense, child: Text('Expense')),
                    ],
                    onChanged: (value) {
                      ref.read(transactionFilterProvider.notifier).state = filter.copyWith(
                        type: value,
                        clearType: value == null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: filter.category,
                    decoration: const InputDecoration(labelText: 'Category', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
                    ],
                    onChanged: (value) {
                      ref.read(transactionFilterProvider.notifier).state = filter.copyWith(
                        category: value,
                        clearCategory: value == null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No transactions found'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90, top: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      return TransactionTile(
                        transaction: t,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditTransactionScreen(existing: t),
                          ),
                        ),
                        onDelete: () =>
                            ref.read(transactionProvider.notifier).deleteTransaction(t.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
