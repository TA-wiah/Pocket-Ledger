import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../services/hive_service.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/pin_utils.dart';

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier() : super(_load());

  static SettingsModel _load() {
    return HiveService.settingsBox.get(HiveService.settingsKey) ?? SettingsModel();
  }

  Future<void> _persist(SettingsModel updated) async {
    await HiveService.settingsBox.put(HiveService.settingsKey, updated);
    state = HiveService.settingsBox.get(HiveService.settingsKey)!;
  }

  Future<void> toggleDarkMode(bool value) => _persist(state.copyWith(isDarkMode: value));

  Future<void> setCurrency(String code) => _persist(state.copyWith(
        currencyCode: code,
        currencySymbol: supportedCurrencies[code] ?? '\$',
      ));

  Future<void> setLanguage(String language) => _persist(state.copyWith(language: language));

  Future<void> setPin(String pin) async {
    final salt = PinUtils.generateSalt();
    final hash = PinUtils.hashPin(pin, salt);
    await _persist(state.copyWith(isPinEnabled: true, pinHash: hash, pinSalt: salt));
  }

  bool verifyPin(String pin) {
    final hash = state.pinHash;
    final salt = state.pinSalt;
    if (hash == null || salt == null) return false;
    return PinUtils.verifyPin(pin, salt, hash);
  }

  Future<void> disablePin() => _persist(state.copyWith(
        isPinEnabled: false,
        clearPinHash: true,
        clearPinSalt: true,
      ));
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (ref) => SettingsNotifier(),
);

final isDarkModeProvider = Provider<bool>((ref) => ref.watch(settingsProvider).isDarkMode);

final currencySymbolProvider =
    Provider<String>((ref) => ref.watch(settingsProvider).currencySymbol);

final isPinEnabledProvider = Provider<bool>((ref) => ref.watch(settingsProvider).isPinEnabled);
