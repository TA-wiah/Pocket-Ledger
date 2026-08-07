import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/person_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import 'person_detail_screen.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(personBalancesProvider);
    final symbol = ref.watch(currencySymbolProvider);

    final totalOutstanding = balances.fold(0.0, (sum, b) => sum + b.balance);

    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditPersonDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Person'),
      ),
      body: balances.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No people added yet',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a person to track money given to and received from them, like a caretaker or student.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Outstanding', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        CurrencyFormatter.format(totalOutstanding, symbol: symbol),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: totalOutstanding > 0 ? AppColors.expense : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Given'), numeric: true),
                        DataColumn(label: Text('Returned'), numeric: true),
                        DataColumn(label: Text('Balance'), numeric: true),
                        DataColumn(label: Text('Last Activity')),
                      ],
                      rows: balances.map((b) {
                        return DataRow(
                          onSelectChanged: (_) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PersonDetailScreen(personId: b.person.id),
                            ),
                          ),
                          cells: [
                            DataCell(Text(b.person.name)),
                            DataCell(Text(CurrencyFormatter.formatCompact(b.given, symbol: symbol))),
                            DataCell(Text(CurrencyFormatter.formatCompact(b.received, symbol: symbol))),
                            DataCell(Text(
                              CurrencyFormatter.formatCompact(b.balance, symbol: symbol),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: b.balance > 0
                                    ? AppColors.expense
                                    : (b.balance < 0 ? AppColors.income : null),
                              ),
                            )),
                            DataCell(Text(
                              b.lastActivity != null ? AppDateUtils.formatDayMonth(b.lastActivity!) : '—',
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showAddEditPersonDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              ref.read(personProvider.notifier).addPerson(
                    name: name,
                    notes: notesController.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
