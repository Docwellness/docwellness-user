import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/goal_journey/controllers/timeline_controller.dart';
import 'package:docwellness/app/modules/goal_journey/services/timeline_service.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/controllers/water_controller.dart';
import 'package:docwellness/app/modules/home/widgets/log_meal_sheet.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Bottom sheet opened by tapping a MilestoneNode - shows the milestone's
/// tasks (if any), grouped via TaskGroups: the 7 real meal serving-times
/// collapse into one expandable "Log Meal" x/7 progress card, Water Intake
/// gets its own progress card, Supplements (optional, no log source of its
/// own) gets its own dashed-border card excluded from both totals, and
/// everything else (Walk, Sleep, dietician-custom tasks) renders as plain
/// checkbox rows same as before. For today, tapping an unlogged meal or the
/// Supplements card routes to where it actually gets logged (see
/// _LogMealProgressCard / _openSupplements), and the Water card is a live
/// +/- control shared with the Home water card - for any other day both
/// fall back to a read-only view of that day's own data. A milestone with
/// no tasks (most weekly/monthly/end_goal nodes - see seedGoalTimeline.js)
/// just shows its date/subtitle with no checklist. Weight/measurements have
/// no task of their own, so still fetched separately via GET
/// /api/patient/timeline/days/:date/logs for the WEIGH-IN block.
class MilestoneSheet extends StatefulWidget {
  final Milestone milestone;
  final ScrollController? scrollController;

  const MilestoneSheet({super.key, required this.milestone, this.scrollController});

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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
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
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        final groups = TaskGroups.from(current.tasks);
                        return Column(
                          children: [
                            if (groups.mealTotal > 0)
                              _LogMealProgressCard(groups: groups, milestone: current, controller: controller),
                            if (groups.waterTask != null)
                              _WaterProgressCard(
                                task: groups.waterTask!,
                                date: current.date,
                                isToday: current.status == MilestoneStatus.active,
                              ),
                            ...groups.otherTasks.map(
                              (task) => taskRow(task, onTap: () => controller.toggleTask(current, task)),
                            ),
                            if (groups.supplementsTask != null)
                              _SupplementsCard(task: groups.supplementsTask!),
                          ],
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
                      if (!_loadingLogs)
                        Obx(() {
                          // Same live re-read as the TASKS section's Obx
                          // above - without this, toggling a task (or the
                          // Water card crossing its goal) updated the
                          // checkbox instantly but left this summary's "x/N
                          // tasks done" frozen at whatever it was when the
                          // sheet first opened, since it was reading the
                          // widget's own static `milestone` param instead of
                          // the reactive controller.milestones list.
                          final current = controller.milestones
                                  .firstWhereOrNull((m) => m.id == milestone.id) ??
                              milestone;
                          return _DaySummaryStrip(milestone: current);
                        }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One task row - icon, title, metric/logged-detail, and a trailing
/// checkbox (manual tasks) or "Logged"/"Not logged" label (linked tasks,
/// read-only). Shared between the "other tasks" list and DayLogsSheet-style
/// read-only renders.
Widget taskRow(GoalTask task, {VoidCallback? onTap}) {
  const maroon = Color(0xff851653);
  const deep = Color(0xff530630);
  const muted = Color(0xff98A2AD);

  final row = Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: task.done ? const Color(0xffF0FBF6) : const Color(0xffFEF6FB),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: task.done ? const Color(0xffBEE8D4) : const Color(0xffFCE7F6)),
    ),
    child: Row(
      children: [
        Icon(task.icon, size: 20, color: task.done ? const Color(0xff1F8A5B) : maroon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(text: task.title, fontWeight: FontWeight.w600, fontSize: 13.5, color: deep),
              if (task.linked && task.loggedNote != null)
                CustomText(
                  text: task.loggedNote!,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: const Color(0xff1F8A5B),
                )
              else if (task.metric.isNotEmpty)
                CustomText(text: task.metric, fontWeight: FontWeight.w400, fontSize: 11, color: muted),
            ],
          ),
        ),
        if (task.linked)
          CustomText(
            text: task.done ? 'Logged' : 'Not logged',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: task.done ? const Color(0xff1F8A5B) : muted,
          )
        else
          Icon(
            task.done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 22,
            color: task.done ? const Color(0xff1F8A5B) : const Color(0xffE9C6DC),
          ),
      ],
    ),
  );
  // A linked-and-done row (meal already logged) has nothing left to do here
  // and stays read-only; a linked-and-not-done row is now tappable too - it
  // routes to logging that meal (see _LogMealProgressCardState._onMealTaskTap)
  // instead of being a dead tap target.
  final tappable = onTap != null && (!task.linked || !task.done);
  return tappable ? GestureDetector(onTap: onTap, child: row) : row;
}

/// A thin progress bar - shared visual for both the Log Meal and Water
/// Intake cards below.
Widget _progressBar(double value, {required bool complete}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Stack(
      children: [
        Container(height: 5, color: const Color(0xffFCE7F6)),
        FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          child: Container(
            height: 5,
            color: complete ? const Color(0xff1F8A5B) : const Color(0xff851653),
          ),
        ),
      ],
    ),
  );
}

/// Closes this milestone sheet and the full-page timeline behind it, then
/// switches Home to the Diet tab's Supplements sub-tab - where supplements
/// actually get logged (there's no dedicated log model for them, so a
/// manual checkbox here would be a state that can never be read back as
/// "done" on its own). Shared by the standalone Supplements card below.
void _openSupplements() {
  Get.back(); // close this milestone sheet
  Get.back(); // pop the full-page timeline back to Home/BottomNaviBar
  Get.find<HomeController>().changeTab(2); // Diet tab
  Get.find<DietController>().focusTabRequest.value = 7; // Supplements sub-tab
}

/// "Supplements" - optional and pulled out of the Log Meal group into its
/// own card (see TaskGroups.supplementsTask), so it neither affects Log
/// Meal's x/7 count nor the "x/N tasks done" summary. The dashed border is
/// the at-a-glance cue that it's optional rather than a required task.
/// Tapping an unlogged card routes to the Diet screen's Supplements tab;
/// a logged one is read-only, same as any other done task row.
class _SupplementsCard extends StatelessWidget {
  final GoalTask task;
  const _SupplementsCard({required this.task});

  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);
  static const _muted = Color(0xff98A2AD);
  static const _done = Color(0xff1F8A5B);

  @override
  Widget build(BuildContext context) {
    final complete = task.done;
    final card = CustomPaint(
      painter: _DashedRRectBorderPainter(
        color: complete ? const Color(0xffBEE8D4) : const Color(0xffE9C6DC),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: complete ? const Color(0xffF0FBF6) : const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(task.icon, size: 20, color: complete ? _done : _maroon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      text: 'Supplements',
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: _deep,
                    ),
                    const CustomText(
                      text: 'Optional',
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      color: _muted,
                    ),
                  ],
                ),
              ),
              Icon(
                complete ? Icons.check_circle : Icons.chevron_right,
                size: complete ? 22 : 20,
                color: complete ? _done : _muted,
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: complete ? card : GestureDetector(onTap: _openSupplements, child: card),
    );
  }
}

/// Draws a dashed rounded-rect outline - this app has no dotted-border
/// package dependency, and pulling one in just for the Supplements card's
/// "optional" treatment isn't worth it, so a small CustomPainter stands in.
class _DashedRRectBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;

  const _DashedRRectBorderPainter({
    required this.color,
    this.radius = 12,
    this.strokeWidth = 1.2,
    this.dashWidth = 5,
    this.gapWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.gapWidth != gapWidth;
}

/// "Log Meal" - one expandable progress card standing in for the 7 real
/// meal serving-times (see TaskGroups - Supplements is optional and lives
/// in its own card outside this group). Shows an x/7 progress bar until
/// every one of them is logged, then collapses to a plain checkmark row;
/// tapping expands/collapses the 7 individual sub-rows (each rendered like
/// any other task row). A not-yet-logged row opens Log Meal focused on
/// that serving time - see _onMealTaskTap.
class _LogMealProgressCard extends StatefulWidget {
  final TaskGroups groups;
  final Milestone milestone;
  final TimelineController controller;

  const _LogMealProgressCard({
    required this.groups,
    required this.milestone,
    required this.controller,
  });

  @override
  State<_LogMealProgressCard> createState() => _LogMealProgressCardState();
}

class _LogMealProgressCardState extends State<_LogMealProgressCard> {
  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);
  static const _muted = Color(0xff98A2AD);
  static const _done = Color(0xff1F8A5B);

  bool _expanded = false;

  // Meal-linked sub-rows (Morning Drink...Night Drink) route to Log Meal,
  // pre-focused on that serving time, when not yet logged - a done one has
  // nothing left to tap for (see taskRow's tappable gating).
  void _onMealTaskTap(GoalTask task) {
    if (task.linked) {
      if (!task.done) _openLogMeal(task.title);
      return;
    }
    widget.controller.toggleTask(widget.milestone, task);
  }

  void _openLogMeal(String servingTitle) {
    Get.back(); // close this milestone sheet first so Log Meal opens alone
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 1,
          maxChildSize: 1,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => LogMealSheet(
            scrollController: scrollController,
            initialServing: servingTitle,
            // This card can represent any day's milestone, not just
            // today's (Goal Journey lets you open a past checkpoint) -
            // without this the sheet always defaulted to today, so
            // logging a missed meal from a past checkpoint silently
            // logged it under today instead.
            initialDate: widget.milestone.date,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups;
    final complete = groups.mealComplete;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: complete ? const Color(0xffF0FBF6) : const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: complete ? const Color(0xffBEE8D4) : const Color(0xffFCE7F6)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, size: 20, color: complete ? _done : _maroon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomText(
                          text: 'Log Meal',
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: _deep,
                        ),
                        if (!complete) ...[
                          const SizedBox(height: 6),
                          _progressBar(groups.mealTotal == 0 ? 0 : groups.mealDone / groups.mealTotal,
                              complete: false),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (complete)
                    const Icon(Icons.check_circle, size: 22, color: _done)
                  else
                    CustomText(
                      text: '${groups.mealDone}/${groups.mealTotal}',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: _muted,
                    ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: const Icon(Icons.expand_more, size: 18, color: _muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Column(
                      children: groups.mealTasks
                          .map((task) => taskRow(task, onTap: () => _onMealTaskTap(task)))
                          .toList(),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// "Water Intake" - for today, an interactive card with the same +/- controls
/// as the Home water card, both reading/writing the one shared
/// WaterController (WaterController.currentIntake/dailyGoal, debounced-synced
/// to the backend - see WaterController.onInit) so the two stay in lockstep
/// instead of this one showing yesterday's /timeline-fetched snapshot while
/// today's un-synced taps pile up elsewhere. A past (already-happened) day
/// gets its own live card too - see _PastDayWaterCard - so a missed day's
/// water can be logged after the fact, same as Log Meal already allows.
/// Only a future day (a milestone that hasn't happened yet) falls back to
/// the plain read-only view driven by the task's own `progress`/
/// `loggedNote` (from that day's /timeline data) - there's nothing to log
/// yet.
class _WaterProgressCard extends StatelessWidget {
  final GoalTask task;
  final DateTime date;
  final bool isToday;
  const _WaterProgressCard({required this.task, required this.date, required this.isToday});

  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);
  static const _muted = Color(0xff98A2AD);
  static const _done = Color(0xff1F8A5B);

  bool get _isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    if (isToday && Get.isRegistered<WaterController>()) {
      return _LiveWaterCard(icon: task.icon);
    }
    if (!_isFuture && Get.isRegistered<WaterController>()) {
      return _PastDayWaterCard(icon: task.icon, date: date, fallbackTask: task);
    }

    final complete = task.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: complete ? const Color(0xffF0FBF6) : const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: complete ? const Color(0xffBEE8D4) : const Color(0xffFCE7F6)),
      ),
      child: Row(
        children: [
          Icon(task.icon, size: 20, color: complete ? _done : _maroon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(text: 'Water Intake', fontWeight: FontWeight.w600, fontSize: 13.5, color: _deep),
                if (!complete) ...[
                  const SizedBox(height: 6),
                  _progressBar(task.progress ?? 0, complete: false),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (complete)
            const Icon(Icons.check_circle, size: 22, color: _done)
          else
            CustomText(
              text: task.loggedNote ?? '',
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: _muted,
            ),
        ],
      ),
    );
  }
}

class _LiveWaterCard extends StatelessWidget {
  final IconData icon;
  const _LiveWaterCard({required this.icon});

  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);
  static const _muted = Color(0xff98A2AD);
  static const _done = Color(0xff1F8A5B);

  @override
  Widget build(BuildContext context) {
    final wc = Get.find<WaterController>();
    return Obx(() {
      final complete = wc.progressPercent >= 1.0;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: complete ? const Color(0xffF0FBF6) : const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: complete ? const Color(0xffBEE8D4) : const Color(0xffFCE7F6)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: complete ? _done : _maroon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText(
                        text: 'Water Intake',
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: _deep,
                      ),
                      const SizedBox(height: 6),
                      _progressBar(wc.progressPercent, complete: complete),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (complete)
                  const Icon(Icons.check_circle, size: 22, color: _done)
                else
                  CustomText(
                    text: '${wc.currentIntakeFormatted}/${wc.goalFormatted} L',
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: _muted,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: wc.removeWater,
                  child: const Icon(Icons.remove_circle_outline, size: 26, color: _maroon),
                ),
                const SizedBox(width: 14),
                CustomText(
                  text: '${wc.stepSize.value.toStringAsFixed(2)} L',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _muted,
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: wc.addWater,
                  child: const Icon(Icons.add_circle, size: 26, color: _maroon),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// "Water Intake" for an already-passed (non-today) day - an add-only live
/// card backed by WaterController.viewedDate/viewedIntake (see
/// WaterController.setViewedDate/addWaterToViewedDay), so a patient can log
/// water they forgot to record on a past day, same as Log Meal already
/// allows there. No remove control: unlike today's entries (held locally
/// and debounce-synced, so a same-session "-" tap can still catch an
/// entry before it ever reaches the backend), every add here syncs
/// immediately - there's no backend endpoint to delete an already-synced
/// entry, so removal isn't safely possible here.
class _PastDayWaterCard extends StatefulWidget {
  final IconData icon;
  final DateTime date;
  // Shown while the real day's total is still loading, so the card isn't
  // blank/zero for a moment on first open.
  final GoalTask fallbackTask;
  const _PastDayWaterCard({required this.icon, required this.date, required this.fallbackTask});

  @override
  State<_PastDayWaterCard> createState() => _PastDayWaterCardState();
}

class _PastDayWaterCardState extends State<_PastDayWaterCard> {
  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);
  static const _muted = Color(0xff98A2AD);
  static const _done = Color(0xff1F8A5B);

  @override
  void initState() {
    super.initState();
    Get.find<WaterController>().setViewedDate(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    final wc = Get.find<WaterController>();
    return Obx(() {
      final loading = wc.isLoadingViewedDay.value;
      final intake = loading ? (widget.fallbackTask.progress ?? 0) * wc.dailyGoal.value : wc.viewedIntake.value;
      final goal = wc.dailyGoal.value;
      final percent = goal > 0 ? (intake / goal).clamp(0.0, 1.0) : 0.0;
      final complete = percent >= 1.0;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: complete ? const Color(0xffF0FBF6) : const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: complete ? const Color(0xffBEE8D4) : const Color(0xffFCE7F6)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 20, color: complete ? _done : _maroon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText(
                        text: 'Water Intake',
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: _deep,
                      ),
                      const SizedBox(height: 6),
                      _progressBar(percent, complete: complete),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (complete)
                  const Icon(Icons.check_circle, size: 22, color: _done)
                else
                  CustomText(
                    text: '${intake.toStringAsFixed(2)}/${goal.toStringAsFixed(1)} L',
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: _muted,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomText(
                  text: '+${wc.stepSize.value.toStringAsFixed(2)} L',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _muted,
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: (loading || wc.isAddingToViewedDay.value) ? null : wc.addWaterToViewedDay,
                  child: wc.isAddingToViewedDay.value
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _maroon),
                        )
                      : const Icon(Icons.add_circle, size: 26, color: _maroon),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Fills what used to be blank space at the bottom of the sheet: a
/// day-at-a-glance strip (conceptual tasks done, total logged calories from
/// the meal group) plus a short motivational line that reacts to how
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
    final groups = TaskGroups.from(tasks);

    final totalCalories = groups.mealTasks
        .where((t) => t.loggedNote != null && t.loggedNote!.contains('kcal'))
        .fold<int>(0, (sum, t) => sum + (int.tryParse(t.loggedNote!.split(' ').first) ?? 0));

    // For today, the water task's `done` flag only updates once the backend
    // has recomputed it from a synced log (see WaterController.syncToBackend
    // - debounced, and the timeline isn't re-fetched after every tap), so it
    // lags behind what the live water card above already shows via
    // wc.progressPercent. Overriding it here with the live check - full
    // goal reached, not just some water logged - keeps this count matching
    // what's actually on screen instead of a stale/premature backend flag.
    final isToday = milestone.status == MilestoneStatus.active;
    final hasLiveWater = isToday && groups.waterTask != null && Get.isRegistered<WaterController>();

    Widget buildCard(int doneCount, int total) {
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

    if (!hasLiveWater) {
      return buildCard(groups.conceptualDone, groups.conceptualTotal);
    }

    return Obx(() {
      final wc = Get.find<WaterController>();
      final liveWaterDone = wc.progressPercent >= 1.0;
      var doneCount = groups.conceptualDone;
      if (liveWaterDone != groups.waterTask!.done) {
        doneCount += liveWaterDone ? 1 : -1;
      }
      return buildCard(doneCount, groups.conceptualTotal);
    });
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
