import 'package:get/get.dart';

import '../../../../main.dart' show userId;
import '../../../models/message_model.dart';
import '../../../services/socket_service.dart';
import '../../diet/controllers/diet_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/water_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // SocketService: needed for live chat/notification updates
    if (!Get.isRegistered<SocketService>()) {
      Get.put(SocketService());
    }

    // DietController: needed by DietPlanScreen in bottom nav
    if (!Get.isRegistered<DietController>()) {
      Get.lazyPut<DietController>(() => DietController(), fenix: true);
    }

    // WaterController is already permanent from main.dart;
    // only create if not already registered (safety fallback)
    if (!Get.isRegistered<WaterController>()) {
      Get.put<WaterController>(WaterController(), permanent: true);
    }

    // Ensure MessageModel knows the current user (needed after fresh login)
    if (userId != null && userId!.isNotEmpty) {
      MessageModel.setCurrentUserId(userId!);
    }

    Get.put<HomeController>(HomeController());
  }
}
