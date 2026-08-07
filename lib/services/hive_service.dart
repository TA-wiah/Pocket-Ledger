import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/settings_model.dart';
import '../models/person_model.dart';
import '../core/constants/default_categories.dart';

class HiveService {
  static const String transactionsBoxName = 'transactions';
  static const String categoriesBoxName = 'categories';
  static const String settingsBoxName = 'settings';
  static const String peopleBoxName = 'people';
  static const String settingsKey = 'app_settings';

  static late Box<TransactionModel> transactionsBox;
  static late Box<CategoryModel> categoriesBox;
  static late Box<SettingsModel> settingsBox;
  static late Box<PersonModel> peopleBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionStatusAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());
    Hive.registerAdapter(PersonModelAdapter());

    transactionsBox = await Hive.openBox<TransactionModel>(transactionsBoxName);
    categoriesBox = await Hive.openBox<CategoryModel>(categoriesBoxName);
    settingsBox = await Hive.openBox<SettingsModel>(settingsBoxName);
    peopleBox = await Hive.openBox<PersonModel>(peopleBoxName);

    if (categoriesBox.isEmpty) {
      for (final category in buildDefaultCategories()) {
        await categoriesBox.put(category.id, category);
      }
    }

    if (settingsBox.get(settingsKey) == null) {
      await settingsBox.put(settingsKey, SettingsModel());
    }
  }

  static Future<void> deleteAllTransactions() async {
    await transactionsBox.clear();
  }

  static Future<void> deleteAllData() async {
    await transactionsBox.clear();
    await categoriesBox.clear();
    await peopleBox.clear();
    for (final category in buildDefaultCategories()) {
      await categoriesBox.put(category.id, category);
    }
  }
}
