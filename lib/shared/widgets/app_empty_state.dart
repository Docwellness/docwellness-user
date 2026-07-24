import 'package:flutter/material.dart';
import 'package:docwellness/core/theme/app_colors.dart';
import 'package:docwellness/core/theme/app_spacing.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';

/// Reusable empty state - AI_EXECUTION_PLAN.md Phase 6, P6-02.
class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const AppEmptyState({
    super.key,
    this.message = 'Nothing here yet.',
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            CustomText(
              text: message,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
