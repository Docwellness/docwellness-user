import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/app/modules/goal_journey/controllers/timeline_controller.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Compact Goal Journey summary card - shown on Home (after ProgressCard)
/// and Progress (after WeightInfoRow). Tapping it opens the full
/// GoalTimelineScreen. Shows a skeleton placeholder while loading (so it
/// occupies its slot alongside the other Home components instead of
/// popping in late), and renders nothing on error/absent-goal, matching
/// MyVideosSection's established "don't show a section with nothing to
/// say" convention.
class JourneyCard extends StatelessWidget {
  const JourneyCard({super.key});

  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);
  static const _rose = Color(0xffC4547F);
  static const _lightBg = Color(0xffFEF6FB);
  static const _border = Color(0xffFCE7F6);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<TimelineController>()
        ? Get.find<TimelineController>()
        : Get.put(TimelineController(), permanent: true);

    return Obx(() {
      if (controller.state.value == TimelineUiState.loading ||
          controller.state.value == TimelineUiState.initial) {
        return const _JourneyCardSkeleton();
      }
      if (controller.state.value == TimelineUiState.error || controller.goal.value == null) {
        return const SizedBox.shrink();
      }

      final goal = controller.goal.value!;
      final stats = controller.stats.value;
      final today = controller.milestones.firstWhereOrNull(
        (m) => m.status == MilestoneStatus.active,
      );
      final dailyMilestones =
          controller.milestones.where((m) => m.type == MilestoneType.daily).toList();
      final todayIndex = dailyMilestones.indexWhere((m) => m.status == MilestoneStatus.active);
      final recentWindow = _centeredWindow(dailyMilestones, todayIndex, 7);
      // Conceptual count (Log Meal + Water Intake + Walk + Sleep = 4), not
      // the raw underlying task-doc count (11) - see TaskGroups.
      final todayGroups = TaskGroups.from(today?.tasks ?? []);
      final todayDone = todayGroups.conceptualDone;
      final todayTotal = todayGroups.conceptualTotal;

      return GestureDetector(
        onTap: () => Get.toNamed(Routes.GOAL_TIMELINE),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 1.2),
            boxShadow: cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CustomText(
                    text: 'GOAL JOURNEY',
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: _rose,
                  ),
                  const Spacer(),
                  if (stats != null && stats.streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF4E5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText(
                        text: '🔥 ${stats.streak}-day streak',
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                        color: const Color(0xffB45309),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    text: goal.currentValue.toStringAsFixed(1),
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                    color: _deep,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3, left: 4),
                    child: CustomText(
                      text: 'kg now',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xff98A2AD),
                    ),
                  ),
                  const Spacer(),
                  CustomText(
                    text: goal.title,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: _maroon,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: goal.progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(height: 6, color: _border),
                      FractionallySizedBox(
                        widthFactor: v.clamp(0.02, 1),
                        child: Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [_rose, _maroon]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _MiniDayStrip(days: recentWindow),
              if (stats != null) ...[
                const SizedBox(height: 6),
                CustomText(
                  text: '${stats.daysElapsed} days completed · ${stats.daysToGo} days remaining',
                  fontWeight: FontWeight.w500,
                  fontSize: 10.5,
                  color: const Color(0xff98A2AD),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: _lightBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      (today?.isFullyDone ?? false) ? Icons.verified : Icons.radio_button_checked,
                      size: 15,
                      color: (today?.isFullyDone ?? false) ? const Color(0xff1F8A5B) : _maroon,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: CustomText(
                        text: (today?.isFullyDone ?? false)
                            ? 'Today complete — streak protected'
                            : 'Today · $todayDone/$todayTotal tasks done',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _deep,
                      ),
                    ),
                    const CustomText(
                      text: 'Full journey',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: _maroon,
                    ),
                    const Icon(Icons.arrow_forward, size: 14, color: _maroon),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Shown in place of the card while its data is loading, so it occupies its
/// slot on Home/Progress at the same time as the surrounding components
/// instead of popping in after everything else has already painted (see
/// JourneyCard's build - it used to return SizedBox.shrink() here).
class _JourneyCardSkeleton extends StatelessWidget {
  const _JourneyCardSkeleton();

  static const _border = Color(0xffFCE7F6);
  static const _bar = Color(0xffF3D9EA);

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: _bar, borderRadius: BorderRadius.circular(6)),
        );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(90, 11),
          const SizedBox(height: 12),
          bar(70, 26),
          const SizedBox(height: 14),
          bar(double.infinity, 6),
          const SizedBox(height: 16),
          bar(double.infinity, 22),
          const SizedBox(height: 12),
          bar(double.infinity, 40),
        ],
      ),
    );
  }
}

/// Picks a `windowSize`-long slice of `days` centered on `todayIndex` - today
/// sits at the middle dot as long as there's enough goal left on both sides;
/// once fewer than `windowSize ~/ 2` future days remain (the final stretch
/// of the goal), the window can't extend further right, so it shifts and
/// today's dot slides toward the right edge instead of falling off the end.
/// Without this, a plain trailing sublist(length-windowSize) shows whichever
/// days are chronologically last in the *whole* goal, which on day 1 of a
/// 28-day goal shows the final week - never today at all.
List<Milestone> _centeredWindow(List<Milestone> days, int todayIndex, int windowSize) {
  if (days.isEmpty) return days;
  final lastIndex = days.length - 1;
  if (todayIndex < 0) {
    final start = (days.length - windowSize).clamp(0, days.length);
    return days.sublist(start);
  }

  final center = windowSize ~/ 2;
  int start = todayIndex - center;
  int end = start + windowSize - 1;
  if (end > lastIndex) {
    start -= (end - lastIndex);
  }
  if (start < 0) start = 0;
  final clampedEnd = (start + windowSize - 1).clamp(0, lastIndex);
  return days.sublist(start, clampedEnd + 1);
}

/// Seven day-dots on a thin line, today shown solid, past days
/// completed/missed colored, future days hollow.
class _MiniDayStrip extends StatelessWidget {
  final List<Milestone> days;
  const _MiniDayStrip({required this.days});

  static const _maroon = Color(0xff851653);
  static const _border = Color(0xffFCE7F6);

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 22,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 6,
            right: 6,
            child: Container(height: 2, color: _border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((m) {
              final isToday = m.status == MilestoneStatus.active;
              final done = m.status == MilestoneStatus.completed;
              final missed = m.status == MilestoneStatus.missed;
              return Container(
                width: isToday ? 14 : 10,
                height: isToday ? 14 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? const Color(0xff1F8A5B)
                      : missed
                          ? const Color(0xffD64545)
                          : isToday
                              ? _maroon
                              : Colors.white,
                  border: Border.all(
                    color: (isToday || done || missed) ? Colors.transparent : const Color(0xffE9C6DC),
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 7, color: Colors.white)
                    : missed
                        ? const Icon(Icons.priority_high, size: 7, color: Colors.white)
                        : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
