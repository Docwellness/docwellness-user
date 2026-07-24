import 'package:flutter/material.dart';
import 'package:docwellness/core/theme/app_colors.dart';

/// Reusable loading indicator - AI_EXECUTION_PLAN.md Phase 6, P6-02.
class AppLoader extends StatelessWidget {
  final Color? color;
  final double size;

  const AppLoader({super.key, this.color, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
