import 'package:get/get.dart';

import '../controllers/diet_controller.dart';

class DietBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DietController>(
      () => DietController(),
    );
  }
}
