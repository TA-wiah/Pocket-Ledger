import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/settings_model.dart';
import '../models/person_model.dart';
import 'hive_service.dart';

class BackupResult {
  final bool success;
  final String message;

  const BackupResult(this.success, this.message);
}

class BackupService {
  BackupService._();

  static const int backupFormatVersion = 1;

  static Map<String, dynamic> _buildBackupJson() {
    return {
      'formatVersion': backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': HiveService.transactionsBox.values.map((t) => t.toJson()).toList(),
      'categories': HiveService.categoriesBox.values.map((c) => c.toJson()).toList(),
      'people': HiveService.peopleBox.values.map((p) => p.toJson()).toList(),
      'settings': (HiveService.settingsBox.get(HiveService.settingsKey) ?? SettingsModel()).toJson(),
    };
  }

  static Future<BackupResult> exportBackup() async {
    try {
      final json = _buildBackupJson();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/pocket_ledger_backup_$timestamp.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));

      await Share.shareXFiles([XFile(file.path)], text: 'Pocket Ledger backup');

      return const BackupResult(true, 'Backup exported successfully');
    } catch (e) {
      return BackupResult(false, 'Failed to export backup: $e');
    }
  }

  static Future<BackupResult> restoreBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) {
        return const BackupResult(false, 'No file selected');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;

      final transactionsJson = (json['transactions'] as List?) ?? [];
      final categoriesJson = (json['categories'] as List?) ?? [];
      final peopleJson = (json['people'] as List?) ?? [];
      final settingsJson = json['settings'] as Map<String, dynamic>?;

      await HiveService.transactionsBox.clear();
      for (final t in transactionsJson) {
        final tx = TransactionModel.fromJson(t as Map<String, dynamic>);
        await HiveService.transactionsBox.put(tx.id, tx);
      }

      await HiveService.categoriesBox.clear();
      for (final c in categoriesJson) {
        final cat = CategoryModel.fromJson(c as Map<String, dynamic>);
        await HiveService.categoriesBox.put(cat.id, cat);
      }

      await HiveService.peopleBox.clear();
      for (final p in peopleJson) {
        final person = PersonModel.fromJson(p as Map<String, dynamic>);
        await HiveService.peopleBox.put(person.id, person);
      }

      if (settingsJson != null) {
        await HiveService.settingsBox.put(
          HiveService.settingsKey,
          SettingsModel.fromJson(settingsJson),
        );
      }

      return const BackupResult(true, 'Backup restored successfully');
    } catch (e) {
      return BackupResult(false, 'Failed to restore backup: $e');
    }
  }
}
