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

  SettingsModel({
    this.isDarkMode = false,
    this.currencyCode = 'USD',
    this.currencySymbol = '\$',
    this.language = 'English',
  });

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
