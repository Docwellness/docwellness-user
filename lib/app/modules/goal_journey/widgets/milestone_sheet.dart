import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/app/modules/goal_journey/controllers/timeline_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Bottom sheet opened by tapping a MilestoneNode - shows the milestone's
/// tasks (if any) with tap-to-check-in, optimistic via
/// TimelineController.toggleTask. A milestone with no tasks (most
/// weekly/monthly/end_goal nodes - see seedGoalTimeline.js) just shows its
/// date/subtitle with no checklist.
class MilestoneSheet extends StatelessWidget {
  final Milestone milestone;

  const MilestoneSheet({super.key, required this.milestone});

  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TimelineController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffFCE7F6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomText(
              text: milestone.title,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: _deep,
            ),
            const SizedBox(height: 4),
            CustomText(
              text:
                  '${milestone.subtitle.isNotEmpty ? '${milestone.subtitle} · ' : ''}${DateFormat('d MMM yyyy').format(milestone.date)}',
              fontWeight: FontWeight.w400,
              fontSize: 12.5,
              color: const Color(0xff98A2AD),
            ),
            const SizedBox(height: 18),
            if (milestone.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CustomText(
                  text: 'No tasks for this checkpoint.',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Color(0xff98A2AD),
                ),
              )
            else
              Obx(() {
                // Re-reads the live milestone from the reactive list (rather
                // than closing over the widget's own `milestone` param) so
                // this rebuilds when toggleTask() calls milestones.refresh()
                // after an optimistic check-in/uncheck.
                final current =
                    controller.milestones.firstWhereOrNull((m) => m.id == milestone.id) ?? milestone;
                return Column(
                  children: current.tasks.map((task) {
                    return GestureDetector(
                      onTap: () => controller.toggleTask(current, task),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: task.done ? const Color(0xffF0FBF6) : const Color(0xffFEF6FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: task.done ? const Color(0xffBEE8D4) : const Color(0xffFCE7F6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(task.icon, size: 20, color: task.done ? const Color(0xff1F8A5B) : _maroon),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: task.title,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                    color: _deep,
                                  ),
                                  if (task.metric.isNotEmpty)
                                    CustomText(
                                      text: task.metric,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                      color: const Color(0xff98A2AD),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 22,
                              color: task.done ? const Color(0xff1F8A5B) : const Color(0xffE9C6DC),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
          ],
        ),
      ),
    );
  }
}
