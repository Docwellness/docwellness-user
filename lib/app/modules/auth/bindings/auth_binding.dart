import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true - a plain (non-permanent) lazyPut here gets disposed
    // by GetX whenever this route is fully popped (e.g. Get.offAll), which
    // then broke every later Get.find<AuthController>() in the onboarding
    // flow with a "not found" crash. The whole flow depends on one
    // AuthController surviving arbitrary route churn, not just this page.
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
