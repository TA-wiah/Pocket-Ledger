import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../services/hive_service.dart';
import '../core/utils/currency_formatter.dart';

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier() : super(_load());

  static SettingsModel _load() {
    return HiveService.settingsBox.get(HiveService.settingsKey) ?? SettingsModel();
  }

  Future<void> _persist(SettingsModel updated) async {
    await HiveService.settingsBox.put(HiveService.settingsKey, updated);
    state = HiveService.settingsBox.get(HiveService.settingsKey)!;
  }

  Future<void> toggleDarkMode(bool value) async {
    await _persist(SettingsModel(
      isDarkMode: value,
      currencyCode: state.currencyCode,
      currencySymbol: state.currencySymbol,
      language: state.language,
    ));
  }

  Future<void> setCurrency(String code) async {
    await _persist(SettingsModel(
      isDarkMode: state.isDarkMode,
      currencyCode: code,
      currencySymbol: supportedCurrencies[code] ?? '\$',
      language: state.language,
    ));
  }

  Future<void> setLanguage(String language) async {
    await _persist(SettingsModel(
      isDarkMode: state.isDarkMode,
      currencyCode: state.currencyCode,
      currencySymbol: state.currencySymbol,
      language: language,
    ));
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (ref) => SettingsNotifier(),
);

final isDarkModeProvider = Provider<bool>((ref) => ref.watch(settingsProvider).isDarkMode);

final currencySymbolProvider =
    Provider<String>((ref) => ref.watch(settingsProvider).currencySymbol);
