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

    // Previously unconditional and non-permanent - every
    // Get.offAllNamed(Routes.HOME) (e.g. from NoDietWidget after choosing a
    // plan) recreated HomeController from scratch, re-firing its onInit()
    // burst of ~6 concurrent API calls. Guarding against redundant puts (like
    // the dependencies above) fixed that, but left HomeController subject to
    // GetX's normal disposal timing - and screens like OrderSummaryView reach
    // it via a plain Get.to() widget push (not a named route), so they never
    // go through this binding and just assume it's already registered. When
    // it wasn't, Get.find() threw, and because main.dart replaces the default
    // red error screen with a blank box, that exception rendered as nothing
    // at all instead of a visible crash. permanent: true (matching
    // WaterController below) removes it from GetX's auto-disposal entirely,
    // so it's simply always there once created.
    if (!Get.isRegistered<HomeController>()) {
      Get.put<HomeController>(HomeController(), permanent: true);
    }
  }
}
