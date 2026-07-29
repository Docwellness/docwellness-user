import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/app/modules/goal_journey/controllers/timeline_controller.dart';
import 'package:docwellness/app/modules/goal_journey/widgets/journey_line_painter.dart';
import 'package:docwellness/app/modules/goal_journey/widgets/milestone_node.dart';
import 'package:docwellness/app/modules/goal_journey/widgets/milestone_sheet.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GoalTimelineScreen extends StatefulWidget {
  const GoalTimelineScreen({super.key});

  @override
  State<GoalTimelineScreen> createState() => _GoalTimelineScreenState();
}

class _GoalTimelineScreenState extends State<GoalTimelineScreen> {
  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);

  late final TimelineController controller;
  final ScrollController _scroll = ScrollController();

  // Type filter chips - null means "all". End Goal is always shown
  // regardless of this filter (see the checklist: "end goal always visible").
  final RxnString _typeFilter = RxnString();

  @override
  void initState() {
    super.initState();
    controller = Get.find<TimelineController>();
    controller.load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocusOrToday());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToFocusOrToday() {
    if (!_scroll.hasClients || controller.milestones.isEmpty) return;
    final focusId = controller.focusMilestoneId.value;
    final idx = focusId != null
        ? controller.milestones.indexWhere((m) => m.id == focusId)
        : controller.milestones.indexWhere((m) => m.status == MilestoneStatus.active);
    if (idx < 0) return;

    final viewport = _scroll.position.viewportDimension;
    final target = (idx * kMilestoneSpacing) - viewport / 2 + kMilestoneSpacing / 2;
    _scroll.animateTo(
      target.clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  void _openMilestone(Milestone milestone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MilestoneSheet(milestone: milestone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
          onPressed: () => Get.back(),
        ),
        title: const CustomText(
          text: 'Your Goal Journey',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: _deep,
        ),
      ),
      body: Obx(() {
        if (controller.state.value == TimelineUiState.loading ||
            controller.state.value == TimelineUiState.initial) {
          return const Center(child: CircularProgressIndicator(color: _maroon));
        }
        if (controller.state.value == TimelineUiState.error || controller.goal.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timeline, size: 40, color: Color(0xff9DA4AE)),
                  const SizedBox(height: 12),
                  CustomText(
                    text: controller.errorMessage.value.isNotEmpty
                        ? controller.errorMessage.value
                        : 'No active goal yet.',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: const Color(0xff4D5761),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => controller.load(),
                    child: const CustomText(
                      text: 'Retry',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _maroon,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final goal = controller.goal.value!;
        final stats = controller.stats.value;

        return SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: goal.title,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: _deep,
                        ),
                        CustomText(
                          text: '${goal.currentValue.toStringAsFixed(1)} ${goal.unit} now',
                          fontWeight: FontWeight.w500,
                          fontSize: 12.5,
                          color: const Color(0xff98A2AD),
                        ),
                      ],
                    ),
                  ),
                  if (stats != null && stats.streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF4E5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText(
                        text: '🔥 ${stats.streak}d',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: const Color(0xffB45309),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: goal.progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(height: 6, color: const Color(0xffFCE7F6)),
                      FractionallySizedBox(
                        widthFactor: v.clamp(0.02, 1),
                        child: Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xffC4547F), _maroon]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (stats != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CustomText(
                      text: '${stats.daysToGo} days to go',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: const Color(0xff98A2AD),
                    ),
                    const CustomText(
                      text: '  ·  ',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: Color(0xff98A2AD),
                    ),
                    CustomText(
                      text: '${(stats.adherence30d * 100).toInt()}% adherence (30d)',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: const Color(0xff98A2AD),
                    ),
                    if (stats.onPace != null) ...[
                      const Spacer(),
                      Icon(
                        stats.onPace! ? Icons.trending_up : Icons.trending_flat,
                        size: 14,
                        color: stats.onPace! ? const Color(0xff1F8A5B) : const Color(0xffD97706),
                      ),
                      const SizedBox(width: 4),
                      CustomText(
                        text: stats.onPace! ? 'On pace' : 'Behind pace',
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: stats.onPace! ? const Color(0xff1F8A5B) : const Color(0xffD97706),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _FilterChips(selected: _typeFilter),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffFCE7F6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _maroon.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SizedBox(
                height: kNodeDotAreaHeight + 34,
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(() {
                    final milestones = controller.milestones;
                    final filter = _typeFilter.value;
                    final width = milestones.length * kMilestoneSpacing;
                    return SizedBox(
                      width: width,
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          // Explicit top+height (not just left/right) gives
                          // CustomPaint a determinate, correctly-sized canvas
                          // via tight constraints - centerY then draws exactly
                          // through the same baseline every node's circle is
                          // centered on (see MilestoneNode's matching
                          // kNodeDotAreaHeight-tall slot), instead of the
                          // ambiguous 1px-canvas-centered-by-Stack-alignment
                          // layout this replaced.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: kNodeDotAreaHeight,
                            child: CustomPaint(
                              painter: JourneyLinePainter(
                                statuses: milestones.map((m) => m.status).toList(),
                                centerY: kNodeDotAreaHeight / 2,
                              ),
                            ),
                          ),
                          Row(
                            children: milestones.map((m) {
                              final isFilteredOut = filter != null &&
                                  filter != 'end_goal' &&
                                  m.type != MilestoneType.endGoal &&
                                  m.type.name != filter;
                              return MilestoneNode(
                                milestone: m,
                                isDimmed: isFilteredOut,
                                onTap: () => _openMilestone(m),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          ),
        );
      }),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final RxnString selected;
  const _FilterChips({required this.selected});

  static const _options = [
    {'label': 'All', 'value': null},
    {'label': 'Daily', 'value': 'daily'},
    {'label': 'Weekly', 'value': 'weekly'},
    {'label': 'Monthly', 'value': 'monthly'},
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        height: 34,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _options.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final option = _options[index];
            final isSelected = selected.value == option['value'];
            return GestureDetector(
              onTap: () => selected.value = option['value'],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xff851653) : const Color(0xffFEF6FB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xffFCE7F6),
                  ),
                ),
                child: Center(
                  child: CustomText(
                    text: option['label'] as String,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSelected ? Colors.white : const Color(0xff530630),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
