import 'package:get/get.dart';

import '../models/grocery_model.dart';
import '../services/grocery_service.dart';

class GroceryController extends GetxController {
  final GroceryService _service = GroceryService();

  final RxList<GroceryItem> allItems = <GroceryItem>[].obs;
  final RxList<GroceryItem> filteredItems = <GroceryItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString selectedCategory = 'All'.obs;

  // Built from whichever ingredient categories are actually present in this
  // week's grocery list (see Recipe.ingredients.category's enum in backend
  // models/Recipe.js) rather than a fixed guess - so every real category
  // (Vegetable, Spice, Dairy, Fruit, Grain, etc.) gets its own tab, no tab
  // is ever empty, and a category that stops appearing doesn't leave a
  // dead tab behind. 'Supplements' is a separate pseudo-category (grouped
  // by isSupplement, not by ingredient category) since supplement line
  // items don't go through the food-ingredient category tagging at all.
  final RxList<String> categories = <String>['All'].obs;

  @override
  void onInit() {
    super.onInit();
    fetchGroceries();
  }

  Future<void> fetchGroceries() async {
    isLoading.value = true;
    error.value = '';
    try {
      final items = await _service.fetchGroceries();
      allItems.assignAll(items);
      _rebuildCategories();
      _applyFilter();
    } catch (e) {
      error.value = 'Failed to load grocery list.';
    } finally {
      isLoading.value = false;
    }
  }

  void filterByCategory(String tab) {
    selectedCategory.value = tab;
    _applyFilter();
  }

  void togglePurchased(int index) {
    if (index < 0 || index >= filteredItems.length) return;
    filteredItems[index].purchased = !filteredItems[index].purchased;
    filteredItems.refresh();
  }

  void _rebuildCategories() {
    final foodCategories = <String>{};
    var hasSupplements = false;
    for (final item in allItems) {
      if (item.isSupplement) {
        hasSupplements = true;
      } else if ((item.category ?? '').isNotEmpty) {
        foodCategories.add(item.category!);
      }
    }
    final sorted = foodCategories.toList()..sort();
    categories.assignAll([
      'All',
      if (hasSupplements) 'Supplements',
      ...sorted,
    ]);
    if (!categories.contains(selectedCategory.value)) {
      selectedCategory.value = 'All';
    }
  }

  void _applyFilter() {
    final tab = selectedCategory.value;
    if (tab == 'All') {
      filteredItems.assignAll(allItems);
    } else if (tab == 'Supplements') {
      filteredItems.assignAll(allItems.where((item) => item.isSupplement));
    } else {
      filteredItems.assignAll(
        allItems.where((item) => !item.isSupplement && item.category == tab),
      );
    }
  }
}
