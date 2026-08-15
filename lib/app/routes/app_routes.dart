part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const HOME = _Paths.HOME;
  static const AUTH = _Paths.AUTH;
  static const PROGRESS = _Paths.PROGRESS;
  static const DIET = _Paths.DIET;
  static const GROCERY = _Paths.GROCERY;
  static const PROFILE = _Paths.PROFILE;
  static const EDIT_PROFILE = _Paths.EDIT_PROFILE;
  static const CHAT = _Paths.CHAT;
  static const CHAT_LIST = _Paths.CHAT_LIST;
  static const NOTIFICATIONS = _Paths.NOTIFICATIONS;
  static const MAIN_REQUEST_DIET_PLAN = _Paths.MAIN_REQUEST_DIET_PLAN;
  static const ORDER_SUMMARY = _Paths.ORDER_SUMMARY;
  static const REQUEST_DIET_PLAN_SCREEN = _Paths.REQUEST_DIET_PLAN_SCREEN;
  static const NO_DIET = _Paths.NO_DIET;
  static const GOAL_TIMELINE = _Paths.GOAL_TIMELINE;
  static const EXERCISE = _Paths.EXERCISE;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const HOME = '/home';
  static const AUTH = '/auth';
  static const PROGRESS = '/progress';
  static const DIET = '/diet';
  static const GROCERY = '/grocery';
  static const PROFILE = '/profile';
  static const EDIT_PROFILE = '/edit-profile';
  static const CHAT = '/chat';
  static const CHAT_LIST = '/chat-list';
  static const NOTIFICATIONS = '/notifications';
  // These match the route names GetX auto-generates for widget-based
  // Get.to() pushes of these screens (their class name) - registering them
  // properly means a cold reload/refresh landing on one of these hashes can
  // actually resolve it instead of GetMaterialApp's initialRoutesGenerate
  // crashing on an unregistered route.
  static const MAIN_REQUEST_DIET_PLAN = '/MainRequestDietPlanView';
  static const ORDER_SUMMARY = '/OrderSummaryView';
  static const REQUEST_DIET_PLAN_SCREEN = '/RequestDietPlanScreen';
  static const NO_DIET = '/NoDietWidget';
  static const GOAL_TIMELINE = '/goal-timeline';
  static const EXERCISE = '/exercise';
}
