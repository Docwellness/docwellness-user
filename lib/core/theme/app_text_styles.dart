import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text style scale - AI_EXECUTION_PLAN.md Phase 6, P6-01.
/// Uses GoogleFonts.roboto to match the existing `CustomText` widget
/// (`lib/utils/app_theme/custom_text.dart`), which every screen already
/// uses - these tokens are a named scale on top of the same font, not a
/// replacement for that widget.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading1 = GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle heading2 = GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle title = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMuted = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle caption = GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static TextStyle button = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}
