import 'package:flutter/material.dart';

/// Design tokens - AI_EXECUTION_PLAN.md Phase 6, P6-01.
///
/// This app has no prior shared color system - the same hex literals
/// (e.g. the brand maroon `0xff851653`) are redeclared independently in
/// 200+ places across `lib/` (see `bottom_navi_bar.dart`'s file-local
/// `maroonColor`/`lightPink` consts for one example). These tokens capture
/// the values already in use today so NEW code has a single source of
/// truth to build on - existing call sites are left untouched here
/// (migrating them is a separate, much larger change, out of scope for
/// this additive phase).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xff851653);
  static const Color primaryDark = Color(0xff530630);
  static const Color primaryLight = Color(0xffFEF6FB);

  static const Color textPrimary = Color(0xff1A1A1A);
  static const Color textSecondary = Color(0xff4D5761);
  static const Color textMuted = Color(0xff9CA3AF);

  static const Color background = Color(0xffFEF6FB);
  static const Color surface = Colors.white;

  static const Color success = Color(0xff2E7D32);
  static const Color error = Color(0xffD32F2F);
  static const Color warning = Color(0xffED6C02);

  static const Color border = Color(0xffE5E7EB);
  static const Color divider = Color(0xffE5E7EB);
}
