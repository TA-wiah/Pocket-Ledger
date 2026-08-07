import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/hive_service.dart';

class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  CategoryNotifier() : super(HiveService.categoriesBox.values.toList());

  void _refresh() => state = HiveService.categoriesBox.values.toList();

  Future<void> addCategory({
    required String name,
    required int iconCodePoint,
    required int colorValue,
    required TransactionType applicableType,
  }) async {
    final category = CategoryModel(
      id: const Uuid().v4(),
      name: name,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      applicableType: applicableType,
      isCustom: true,
    );
    await HiveService.categoriesBox.put(category.id, category);
    _refresh();
  }

  Future<void> toggleFavorite(String id) async {
    final category = HiveService.categoriesBox.get(id);
    if (category == null) return;
    category.isFavorite = !category.isFavorite;
    await category.save();
    _refresh();
  }

  Future<void> deleteCategory(String id) async {
    await HiveService.categoriesBox.delete(id);
    _refresh();
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<CategoryModel>>(
  (ref) => CategoryNotifier(),
);

final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(categoryProvider).where((c) => c.applicableType == TransactionType.income).toList();
});

final expenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(categoryProvider).where((c) => c.applicableType == TransactionType.expense).toList();
});
