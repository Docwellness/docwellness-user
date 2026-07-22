import 'package:get/get.dart';

import '../modules/Progress/bindings/progress_binding.dart';
import '../modules/Progress/views/progress_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/chat/bindings/chat_binding.dart';
import '../modules/chat/bindings/chat_list_binding.dart';
import '../modules/chat/views/chat_list_view.dart';
import '../modules/chat/views/chat_view.dart';
import '../modules/diet/bindings/diet_binding.dart';
import '../modules/diet/views/diet_view.dart';
import '../modules/edit_profile/bindings/edit_profile_binding.dart';
import '../modules/edit_profile/views/edit_profile_view.dart';
import '../modules/grocery/bindings/grocery_binding.dart';
import '../modules/grocery/views/grocery_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/bottom_navi_bar.dart';
import '../modules/home/views/main_request_diet_plan_view.dart';
import '../modules/home/views/order_summary_view.dart';
import '../modules/home/widgets/no_diet_widget.dart';
import '../modules/home/widgets/request_diet_plan.view.dart';
import '../modules/notifications/bindings/notification_binding.dart';
import '../modules/notifications/views/notification_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(name: _Paths.SPLASH, page: () => const SplashView()),
    GetPage(
      name: _Paths.HOME,
      page: () => BottomNaviBar(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),

      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.PROGRESS,
      page: () => const ProgressView(),
      binding: ProgressBinding(),
    ),
    GetPage(
      name: _Paths.DIET,
      page: () => DietPlanScreen(),
      binding: DietBinding(),
    ),
    GetPage(
      name: _Paths.GROCERY,
      page: () => const GroceryView(),
      binding: GroceryBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_PROFILE,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: _Paths.CHAT,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: _Paths.CHAT_LIST,
      page: () => const ChatListView(),
      binding: ChatListBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATIONS,
      page: () => const NotificationView(),
      binding: NotificationBinding(),
    ),
    // Not linked from bottom-nav - reached via Get.to() from within Home,
    // but registered so a cold reload/refresh on one of these routes
    // resolves instead of crashing (see _Paths comment). binding:
    // HomeBinding() so HomeController etc. exist even if this is the very
    // first route the app boots into (e.g. a stale deep link), not just
    // when reached by navigating through /home first.
    GetPage(
      name: _Paths.MAIN_REQUEST_DIET_PLAN,
      page: () => MainRequestDietPlanView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.ORDER_SUMMARY,
      page: () => const OrderSummaryView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.REQUEST_DIET_PLAN_SCREEN,
      page: () => const RequestDietPlanScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.NO_DIET,
      page: () => const NoDietWidget(),
      binding: HomeBinding(),
    ),
  ];
}
