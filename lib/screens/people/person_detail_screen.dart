import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/person_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_edit_transaction_screen.dart';

class PersonDetailScreen extends ConsumerWidget {
  final String personId;

  const PersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(personBalancesProvider);
    final allTransactions = ref.watch(transactionProvider);
    final symbol = ref.watch(currencySymbolProvider);

    final balance = balances.where((b) => b.person.id == personId).firstOrNull;
    if (balance == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Person')),
        body: const Center(child: Text('Person not found')),
      );
    }

    final personTransactions = transactionsForPerson(allTransactions, personId);

    return Scaffold(
      appBar: AppBar(
        title: Text(balance.person.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete person',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete person?'),
                  content: Text(
                    'This removes "${balance.person.name}" from People. Their existing transactions will remain but will no longer be linked to this person.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(personProvider.notifier).deletePerson(personId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _row(context, 'Given', balance.given, AppColors.expense, symbol),
                const Divider(height: 20),
                _row(context, 'Returned', balance.received, AppColors.income, symbol),
                const Divider(height: 20),
                _row(
                  context,
                  'Balance',
                  balance.balance,
                  balance.balance > 0 ? AppColors.expense : AppColors.income,
                  symbol,
                  bold: true,
                ),
              ],
            ),
          ),
          if (balance.person.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(balance.person.notes, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          Text(
            'Transaction History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (personTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No transactions linked to this person yet')),
            )
          else
            ...personTransactions.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TransactionTile(
                    transaction: t,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEditTransactionScreen(existing: t)),
                    ),
                    onDelete: () => ref.read(transactionProvider.notifier).deleteTransaction(t.id),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, double value, Color color, String symbol,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          CurrencyFormatter.format(value, symbol: symbol),
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
            fontSize: bold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
