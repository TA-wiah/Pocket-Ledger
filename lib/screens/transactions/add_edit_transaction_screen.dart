import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/person_provider.dart';
import '../../core/utils/date_utils.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existing;
  final TransactionType? initialType;

  const AddEditTransactionScreen({super.key, this.existing, this.initialType});

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  late TransactionType _type;
  String? _category;
  late DateTime _date;
  late TransactionStatus _status;
  String? _personId;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _type = existing?.type ?? widget.initialType ?? TransactionType.income;
    _category = existing?.category;
    _date = existing?.date ?? DateTime.now();
    _status = existing?.status ?? TransactionStatus.completed;
    _personId = existing?.personId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == TransactionType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    if (_category == null || !categories.any((c) => c.name == _category)) {
      _category = categories.isNotEmpty ? categories.first.name : null;
    }

    final people = ref.watch(personProvider);
    final isLoanCategory = _category == 'Loan Given' || _category == 'Loan Received';

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Transaction' : 'Add Record')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  _category = null;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Amount is required';
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _personId,
                    decoration: InputDecoration(
                      labelText: isLoanCategory ? 'Person *' : 'Person (optional)',
                    ),
                    items: [
                      if (!isLoanCategory) const DropdownMenuItem(value: null, child: Text('None')),
                      ...people.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (value) => setState(() => _personId = value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Add new person',
                  onPressed: () => _showAddPersonDialog(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Text(AppDateUtils.formatShort(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TransactionStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: TransactionStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s))))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    final isLoanCategory = _category == 'Loan Given' || _category == 'Loan Received';
    if (isLoanCategory && _personId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a person for this loan')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final notifier = ref.read(transactionProvider.notifier);

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: amount,
        type: _type,
        category: _category,
        date: _date,
        notes: _notesController.text.trim(),
        status: _status,
        personId: _personId,
        clearPersonId: _personId == null,
      );
      await notifier.updateTransaction(updated);
    } else {
      await notifier.addTransaction(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: amount,
        type: _type,
        category: _category!,
        date: _date,
        notes: _notesController.text.trim(),
        status: _status,
        personId: _personId,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _showAddPersonDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Person'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name *'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final person = await ref.read(personProvider.notifier).addPerson(name: name);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() => _personId = person.id);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
