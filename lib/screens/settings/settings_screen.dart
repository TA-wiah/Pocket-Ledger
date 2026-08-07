import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/person_provider.dart';
import '../../services/backup_service.dart';
import '../../core/utils/currency_formatter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark theme'),
            value: settings.isDarkMode,
            onChanged: (value) => ref.read(settingsProvider.notifier).toggleDarkMode(value),
          ),
          ListTile(
            title: const Text('Currency'),
            subtitle: Text('${settings.currencyCode} (${settings.currencySymbol})'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(context, ref),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(settings.language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          const Divider(),
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Backup'),
            subtitle: const Text('Export all data to a JSON file'),
            onTap: () async {
              final result = await BackupService.exportBackup();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(result.message)));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Restore'),
            subtitle: const Text('Restore data from a backup JSON file'),
            onTap: () async {
              final confirmed = await _confirm(
                context,
                title: 'Restore backup?',
                message: 'This will replace all current transactions and categories with the data in the selected backup file.',
                confirmLabel: 'Restore',
              );
              if (confirmed != true) return;
              final result = await BackupService.restoreBackup();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(result.message)));
              }
              ref.invalidate(transactionProvider);
              ref.invalidate(categoryProvider);
              ref.invalidate(personProvider);
              ref.invalidate(settingsProvider);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete All Records', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently delete all transactions'),
            onTap: () async {
              final confirmed = await _confirm(
                context,
                title: 'Delete all records?',
                message: 'This will permanently delete all transactions on this device. This cannot be undone.',
                confirmLabel: 'Delete All',
              );
              if (confirmed == true) {
                await ref.read(transactionProvider.notifier).deleteAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('All records deleted')));
                }
              }
            },
          ),
          const Divider(),
          _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About Pocket Ledger'),
            subtitle: Text('A simple offline bookkeeping app for small businesses and freelancers'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy'),
            subtitle: Text('All data stays on your device. Nothing is uploaded, ever.'),
          ),
          const ListTile(
            leading: Icon(Icons.numbers),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          if (kDebugMode) const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: supportedCurrencies.entries
              .map((e) => ListTile(
                    title: Text('${e.key} (${e.value})'),
                    onTap: () {
                      ref.read(settingsProvider.notifier).setCurrency(e.key);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    const languages = ['English', 'Spanish', 'French', 'Portuguese', 'Swahili'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: languages
              .map((lang) => ListTile(
                    title: Text(lang),
                    onTap: () {
                      ref.read(settingsProvider.notifier).setLanguage(lang);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
