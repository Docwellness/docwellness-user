import 'package:flutter/material.dart';

/// Corner-radius scale - AI_EXECUTION_PLAN.md Phase 6, P6-01.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 100;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
