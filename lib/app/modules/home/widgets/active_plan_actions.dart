import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';

/// The Home action-button area for a patient whose diet plan is currently
/// active (request status Paid / PartiallyPaid, or a renewal in progress
/// while the previous cycle is still running).
///
/// Always shows Log Meal / Log Exercise for the current plan. Once the
/// cycle is within [kRenewalWindowDays] of expiry the caller sets
/// [showRequestDietPlan] and a "Request diet plan" button appears below
/// them - there is deliberately no "Subscription Active" banner here, the
/// Goal Journey card already shows completed/remaining days.
///
/// Split out of HomeView (which wires it to HomeController) so this rule
/// can be widget-tested without standing up the controller - see
/// test/active_plan_actions_test.dart.
class ActivePlanActions extends StatelessWidget {
  /// Gates the two log buttons - false while the diet plan hasn't started
  /// yet (the countdown card is still showing).
  final bool dietEnabled;

  /// Whether to show the "Request diet plan" button under the log buttons
  /// (caller passes HomeController.isRenewalDue).
  final bool showRequestDietPlan;

  final VoidCallback onLogMeal;
  final VoidCallback onLogExercise;
  final VoidCallback onRequestDietPlan;

  const ActivePlanActions({
    super.key,
    required this.dietEnabled,
    required this.showRequestDietPlan,
    required this.onLogMeal,
    required this.onLogExercise,
    required this.onRequestDietPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                enabled: dietEnabled,
                onTap: onLogMeal,
                text: 'Log Meal',
                fontSize: 14,
                isOutline: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                enabled: dietEnabled,
                onTap: onLogExercise,
                text: 'Log Exercise',
                fontSize: 14,
                isOutline: true,
              ),
            ),
          ],
        ),
        if (showRequestDietPlan) ...[
          const SizedBox(height: 12),
          CustomButton(
            onTap: onRequestDietPlan,
            text: 'Request diet plan',
            fontSize: 14,
            isOutline: true,
          ),
        ],
      ],
    );
  }
}
