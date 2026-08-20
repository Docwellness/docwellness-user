import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One-tap "log this at its full planned amount" - additive to the
/// existing Log Meal sheet/portion picker (home/widgets/log_meal_sheet.dart,
/// custom_portion_dropdown.dart), which stays completely untouched and
/// still works exactly as before for a patient who wants to log a partial
/// portion. This button only ever calls
/// DietController.quickLogSingleMeal, never touching selectedPortions.
class QuickLogButton extends StatelessWidget {
  final String servingTime;
  final String recipeId;

  const QuickLogButton({
    super.key,
    required this.servingTime,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DietController>();
    final key = '$servingTime-$recipeId';

    return Obx(() {
      final isLogging = controller.quickLoggingKeys.contains(key);
      final alreadyLogged = controller.isRecipeLogged(servingTime, recipeId);

      return InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: (isLogging || alreadyLogged)
            ? null
            : () async {
                final ok = await controller.quickLogSingleMeal(
                  servingTime,
                  recipeId,
                );
                if (!context.mounted) return;
                showAppToast(
                  context,
                  message: ok ? 'Logged!' : 'Could not log this meal.',
                  type: ok ? AppToastType.success : AppToastType.error,
                );
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: alreadyLogged
                ? const Color(0xffE7F8EF)
                : const Color(0xffFEF6FB),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: alreadyLogged
                  ? const Color(0xff1F8A5B)
                  : const Color(0xff851653),
            ),
          ),
          child: isLogging
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xff851653),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      alreadyLogged ? Icons.check_circle : Icons.check_circle_outline,
                      size: 13,
                      color: alreadyLogged
                          ? const Color(0xff1F8A5B)
                          : const Color(0xff851653),
                    ),
                    const SizedBox(width: 4),
                    CustomText(
                      text: alreadyLogged ? 'Logged' : 'Quick Log',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: alreadyLogged
                          ? const Color(0xff1F8A5B)
                          : const Color(0xff851653),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}
