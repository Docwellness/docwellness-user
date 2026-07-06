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

  // Tab labels mapped to ingredient category values from backend
  static const Map<String, String?> _categoryFilter = {
    'All': null,
    'Vegetables': 'Vegetables',
    'Spices': 'Spices',
    'Diary': 'Dairy',
    'Kitchen': 'Kitchen',
  };

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

  void _applyFilter() {
    final categoryValue = _categoryFilter[selectedCategory.value];
    if (categoryValue == null) {
      filteredItems.assignAll(allItems);
    } else {
      filteredItems.assignAll(
        allItems.where(
          (item) =>
              (item.category ?? '').toLowerCase() ==
              categoryValue.toLowerCase(),
        ),
      );
    }
  }
}
