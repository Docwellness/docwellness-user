import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/app/modules/goal_journey/controllers/timeline_controller.dart';
import 'package:docwellness/app/modules/goal_journey/services/timeline_service.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Bottom sheet opened by tapping a MilestoneNode - shows the milestone's
/// tasks (if any) with tap-to-check-in, optimistic via
/// TimelineController.toggleTask. A milestone with no tasks (most
/// weekly/monthly/end_goal nodes - see seedGoalTimeline.js) just shows its
/// date/subtitle with no checklist. Daily milestones also show what was
/// actually logged that day (meals/weight), via GET
/// /api/patient/timeline/days/:date/logs.
class MilestoneSheet extends StatefulWidget {
  final Milestone milestone;

  const MilestoneSheet({super.key, required this.milestone});

  @override
  State<MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends State<MilestoneSheet> {
  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);
  static const _muted = Color(0xff98A2AD);

  final TimelineService _service = TimelineService();
  bool _loadingLogs = true;
  List<dynamic> _meals = [];
  List<dynamic> _progress = [];

  @override
  void initState() {
    super.initState();
    if (widget.milestone.type == MilestoneType.daily) {
      _loadDayLogs();
    } else {
      _loadingLogs = false;
    }
  }

  Future<void> _loadDayLogs() async {
    final data = await _service.getDayLogs(widget.milestone.date);
    if (!mounted) return;
    setState(() {
      _meals = data?['meals'] as List? ?? [];
      _progress = data?['progress'] as List? ?? [];
      _loadingLogs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TimelineController>();
    final milestone = widget.milestone;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
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
                color: _muted,
              ),
              const SizedBox(height: 18),
              if (milestone.tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CustomText(
                    text: 'No tasks for this checkpoint.',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: _muted,
                  ),
                )
              else ...[
                CustomText(
                  text: 'TASKS',
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                  color: _muted,
                ),
                const SizedBox(height: 8),
                Obx(() {
                  // Re-reads the live milestone from the reactive list
                  // (rather than closing over the widget's own `milestone`
                  // param) so this rebuilds when toggleTask() calls
                  // milestones.refresh() after an optimistic check-in.
                  final current = controller.milestones
                          .firstWhereOrNull((m) => m.id == milestone.id) ??
                      milestone;
                  return Column(
                    children: current.tasks.map((task) {
                      return GestureDetector(
                        onTap: () => controller.toggleTask(current, task),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: task.done
                                ? const Color(0xffF0FBF6)
                                : const Color(0xffFEF6FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: task.done
                                  ? const Color(0xffBEE8D4)
                                  : const Color(0xffFCE7F6),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                task.icon,
                                size: 20,
                                color: task.done ? const Color(0xff1F8A5B) : _maroon,
                              ),
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
                                        color: _muted,
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 22,
                                color: task.done
                                    ? const Color(0xff1F8A5B)
                                    : const Color(0xffE9C6DC),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
              if (milestone.type == MilestoneType.daily) ...[
                const SizedBox(height: 8),
                CustomText(
                  text: 'WHAT YOU LOGGED',
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                  color: _muted,
                ),
                const SizedBox(height: 8),
                if (_loadingLogs)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _maroon),
                      ),
                    ),
                  )
                else ...[
                  if (_meals.isEmpty && _progress.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: CustomText(
                        text: 'Nothing logged this day.',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: _muted,
                      ),
                    ),
                  ..._meals.map((meal) {
                    final m = Map<String, dynamic>.from(meal as Map);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_menu, size: 16, color: _maroon),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomText(
                              text: m['mealType']?.toString() ?? 'Meal',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _deep,
                            ),
                          ),
                          if (m['caloriesConsumed'] != null)
                            CustomText(
                              text: '${m['caloriesConsumed']} kcal',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: _muted,
                            ),
                        ],
                      ),
                    );
                  }),
                  ..._progress.map((p) {
                    final entry = Map<String, dynamic>.from(p as Map);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.monitor_weight, size: 16, color: _maroon),
                          const SizedBox(width: 8),
                          CustomText(
                            text: entry['weight'] != null ? '${entry['weight']} kg logged' : 'Logged',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _deep,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
