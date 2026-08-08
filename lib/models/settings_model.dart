import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 4)
class SettingsModel extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  String currencyCode;

  @HiveField(2)
  String currencySymbol;

  @HiveField(3)
  String language;

  @HiveField(4, defaultValue: false)
  bool isPinEnabled;

  @HiveField(5)
  String? pinHash;

  @HiveField(6)
  String? pinSalt;

  SettingsModel({
    this.isDarkMode = false,
    this.currencyCode = 'USD',
    this.currencySymbol = '\$',
    this.language = 'English',
    this.isPinEnabled = false,
    this.pinHash,
    this.pinSalt,
  });

  SettingsModel copyWith({
    bool? isDarkMode,
    String? currencyCode,
    String? currencySymbol,
    String? language,
    bool? isPinEnabled,
    String? pinHash,
    bool clearPinHash = false,
    String? pinSalt,
    bool clearPinSalt = false,
  }) {
    return SettingsModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      language: language ?? this.language,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      pinHash: clearPinHash ? null : (pinHash ?? this.pinHash),
      pinSalt: clearPinSalt ? null : (pinSalt ?? this.pinSalt),
    );
  }

  // PIN lock state is intentionally excluded from backup/restore JSON:
  // it's device-local security state, not ledger data.
  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
        'language': language,
      };

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
      language: json['language'] as String? ?? 'English',
    );
  }
}
