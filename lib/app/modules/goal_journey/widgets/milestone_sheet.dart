import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/app/modules/goal_journey/controllers/timeline_controller.dart';
import 'package:docwellness/app/modules/goal_journey/services/timeline_service.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Bottom sheet opened by tapping a MilestoneNode - shows the milestone's
/// tasks (if any). Meal-linked tasks (Morning Drink...Night Drink,
/// GoalTask.linked) show their logged detail (calories) inline and are
/// read-only, straight from the same MealLog the backend used to mark them
/// done - no separate "what did I log" list to fall out of sync with the
/// checklist. Supplements is the one task still tap-to-check-in, optimistic
/// via TimelineController.toggleTask. A milestone with no tasks (most
/// weekly/monthly/end_goal nodes - see seedGoalTimeline.js) just shows its
/// date/subtitle with no checklist. Weight/measurements have no task of
/// their own, so still fetched separately via GET
/// /api/patient/timeline/days/:date/logs for the WEIGH-IN block.
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
                      // Meal-linked tasks are read-only (see GoalTask.linked's
                      // doc comment) - their trailing indicator shows the
                      // logged detail instead of a tappable checkbox, so
                      // there's nothing left disconnected from the checklist
                      // for the patient to reconcile themselves.
                      final row = Container(
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
                                  if (task.linked && task.loggedNote != null)
                                    CustomText(
                                      text: task.loggedNote!,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                      color: const Color(0xff1F8A5B),
                                    )
                                  else if (task.metric.isNotEmpty)
                                    CustomText(
                                      text: task.metric,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                      color: _muted,
                                    ),
                                ],
                              ),
                            ),
                            if (task.linked)
                              CustomText(
                                text: task.done ? 'Logged' : 'Not logged',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: task.done ? const Color(0xff1F8A5B) : _muted,
                              )
                            else
                              Icon(
                                task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 22,
                                color: task.done
                                    ? const Color(0xff1F8A5B)
                                    : const Color(0xffE9C6DC),
                              ),
                          ],
                        ),
                      );
                      return task.linked
                          ? row
                          : GestureDetector(onTap: () => controller.toggleTask(current, task), child: row);
                    }).toList(),
                  );
                }),
              ],
              if (milestone.type == MilestoneType.daily) ...[
                const SizedBox(height: 8),
                CustomText(
                  text: 'WEIGH-IN',
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
                else if (_progress.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: CustomText(
                      text: 'No weigh-in logged this day.',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: _muted,
                    ),
                  )
                else
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
                if (!_loadingLogs) _DaySummaryStrip(milestone: milestone),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fills what used to be blank space at the bottom of the sheet: a
/// day-at-a-glance strip (tasks done, total logged calories from the
/// meal-linked tasks) plus a short motivational line that reacts to how
/// complete the day is - closes the sheet on a concrete, encouraging note
/// instead of trailing off after the last logged row.
class _DaySummaryStrip extends StatelessWidget {
  final Milestone milestone;
  const _DaySummaryStrip({required this.milestone});

  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);
  static const _muted = Color(0xff98A2AD);

  @override
  Widget build(BuildContext context) {
    final tasks = milestone.tasks;
    if (tasks.isEmpty) return const SizedBox.shrink();

    final totalCalories = tasks
        .where((t) => t.linked && t.loggedNote != null && t.loggedNote!.contains('kcal'))
        .fold<int>(0, (sum, t) => sum + (int.tryParse(t.loggedNote!.split(' ').first) ?? 0));
    final doneCount = tasks.where((t) => t.done).length;
    final total = tasks.length;
    final ratio = total == 0 ? 0.0 : doneCount / total;

    final message = ratio >= 1
        ? "Perfect day - every task logged. Keep this up!"
        : ratio >= 0.6
            ? "Good progress - a few more to fully close out the day."
            : ratio > 0
                ? "Just getting started today - log the rest when you can."
                : "Nothing logged yet - your dietician can see this too.";

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffFEF6FB), Color(0xffFCE7F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stat(Icons.task_alt, '$doneCount/$total', 'tasks done'),
              const SizedBox(width: 20),
              if (totalCalories > 0) _stat(Icons.local_fire_department, '$totalCalories', 'kcal logged'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: _maroon),
              const SizedBox(width: 6),
              Expanded(
                child: CustomText(
                  text: message,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: _deep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _maroon),
        const SizedBox(width: 6),
        CustomText(text: value, fontWeight: FontWeight.w800, fontSize: 14, color: _deep),
        const SizedBox(width: 4),
        CustomText(text: label, fontWeight: FontWeight.w500, fontSize: 11, color: _muted),
      ],
    );
  }
}
