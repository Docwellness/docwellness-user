import 'package:get/get.dart';

import '../models/grocery_model.dart';
import '../services/grocery_service.dart';

class GroceryController extends GetxController {
  final GroceryService _service = GroceryService();

  // Every ready week's items, fetched once in fetchGroceries() and kept
  // around for the lifetime of this controller - switchWeek below reads
  // straight out of this map, never re-hits the network.
  final RxMap<int, List<GroceryItem>> itemsByWeek = <int, List<GroceryItem>>{}.obs;
  // Sorted ascending - only weeks the dietician has actually finalized (see
  // the backend's getGroceriesForCurrentWeek doc comment), so this is
  // exactly the set of weeks the Week dropdown should offer.
  final RxList<int> readyWeeks = <int>[].obs;
  // 0 = nothing ready yet / not loaded.
  final RxInt selectedWeek = 0.obs;

  final RxList<GroceryItem> filteredItems = <GroceryItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString selectedCategory = 'All'.obs;

  // Built from whichever ingredient categories are actually present in the
  // selected week's grocery list (see Recipe.ingredients.category's enum in
  // backend models/Recipe.js) rather than a fixed guess - so every real
  // category (Vegetable, Spice, Dairy, Fruit, Grain, etc.) gets its own tab,
  // no tab is ever empty, and a category that stops appearing doesn't leave
  // a dead tab behind. 'Supplements' is a separate pseudo-category (grouped
  // by isSupplement, not by ingredient category) since supplement line
  // items don't go through the food-ingredient category tagging at all.
  final RxList<String> categories = <String>['All'].obs;

  @override
  void onInit() {
    super.onInit();
    fetchGroceries();
  }

  List<GroceryItem> get _selectedWeekItems => itemsByWeek[selectedWeek.value] ?? const [];

  Future<void> fetchGroceries() async {
    isLoading.value = true;
    error.value = '';
    try {
      final result = await _service.fetchGroceries();
      itemsByWeek.assignAll({for (final w in result.weeks) w.week: w.items});
      readyWeeks.assignAll(itemsByWeek.keys.toList()..sort());

      if (readyWeeks.isEmpty) {
        selectedWeek.value = 0;
      } else if (result.currentWeek != null && readyWeeks.contains(result.currentWeek)) {
        selectedWeek.value = result.currentWeek!;
      } else {
        selectedWeek.value = readyWeeks.last;
      }

      _rebuildCategories();
      _applyFilter();
    } catch (e) {
      error.value = 'Failed to load grocery list.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Pure client-side swap, same pattern as DietController.switchWeek - every
  /// ready week's items are already cached from fetchGroceries(), so this
  /// never triggers a network call.
  void switchWeek(int week) {
    if (week == selectedWeek.value || !itemsByWeek.containsKey(week)) return;
    selectedWeek.value = week;
    _rebuildCategories();
    _applyFilter();
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
    for (final item in _selectedWeekItems) {
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
    final items = _selectedWeekItems;
    if (tab == 'All') {
      filteredItems.assignAll(items);
    } else if (tab == 'Supplements') {
      filteredItems.assignAll(items.where((item) => item.isSupplement));
    } else {
      filteredItems.assignAll(
        items.where((item) => !item.isSupplement && item.category == tab),
      );
    }
  }
}
