import 'package:get/get.dart';

import '../controllers/grocery_controller.dart';

class GroceryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroceryController>(
      () => GroceryController(),
    );
  }
}
