import 'package:flutter/material.dart';
import 'package:docwellness/core/theme/app_colors.dart';
import 'package:docwellness/core/theme/app_spacing.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';

/// Reusable error state - AI_EXECUTION_PLAN.md Phase 6, P6-02.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AppErrorState({
    super.key,
    this.message = 'Something went wrong.',
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomText(
              text: message,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                button: true,
                label: retryLabel,
                child: TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text(retryLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
