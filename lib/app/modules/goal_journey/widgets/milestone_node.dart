import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

import 'blink_pulse.dart';
import 'journey_line_painter.dart';

/// One node on the timeline, shaped by [Milestone.type]: weekly is a
/// rounded square, daily (and the trophy end-goal) is a circle -
/// MilestoneType.monthly is deliberately not rendered at all here (see
/// TimelineController's/goal_timeline_screen.dart's filtering - monthly
/// milestones never reach this widget). Colored by status, with its date
/// label beneath. The active ("today") node also gets a soft blinking glow
/// (see BlinkPulse) so it's unmistakable which one is current. Tapping
/// opens MilestoneSheet (wired by the parent screen, not here - this widget
/// is purely presentational).
class MilestoneNode extends StatelessWidget {
  final Milestone milestone;
  final VoidCallback onTap;

  const MilestoneNode({
    super.key,
    required this.milestone,
    required this.onTap,
  });

  static const _maroon = Color(0xff851653);
  static const _done = Color(0xff1F8A5B);
  static const _missed = Color(0xffD64545);
  static const _partial = Color(0xffE9A319);

  double get _diameter {
    switch (milestone.type) {
      case MilestoneType.endGoal:
        return 40;
      case MilestoneType.monthly:
      case MilestoneType.weekly:
        return 26;
      case MilestoneType.daily:
        return milestone.status == MilestoneStatus.active ? 20 : 16;
    }
  }

  Color get _color {
    switch (milestone.status) {
      case MilestoneStatus.completed:
        return _done;
      case MilestoneStatus.partial:
        return _partial;
      case MilestoneStatus.missed:
        return _missed;
      case MilestoneStatus.active:
        return _maroon;
      case MilestoneStatus.upcoming:
        return Colors.white;
    }
  }

  Color get _borderColor =>
      milestone.status == MilestoneStatus.upcoming ? const Color(0xffE9C6DC) : Colors.transparent;

  Widget? get _icon {
    if (milestone.type == MilestoneType.endGoal) {
      return const Text('🏆', style: TextStyle(fontSize: 18));
    }
    if (milestone.status == MilestoneStatus.completed) {
      return const Icon(Icons.check, size: 12, color: Colors.white);
    }
    if (milestone.status == MilestoneStatus.missed ||
        milestone.status == MilestoneStatus.partial) {
      return const Icon(Icons.priority_high, size: 12, color: Colors.white);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final diameter = _diameter;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: kMilestoneSpacing,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed-height slot so every node's shape centers on the exact
            // same baseline regardless of its own diameter - see
            // kNodeDotAreaHeight's doc comment in journey_line_painter.dart.
            SizedBox(
              height: kNodeDotAreaHeight,
              child: Center(
                child: milestone.status == MilestoneStatus.active
                    ? BlinkPulse(
                        child: Container(
                          width: diameter + 10,
                          height: diameter + 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _maroon.withValues(alpha: 0.4), width: 2),
                          ),
                          child: Center(child: _dot(diameter)),
                        ),
                      )
                    : _dot(diameter),
              ),
            ),
            const SizedBox(height: 6),
            CustomText(
              text: milestone.title,
              fontWeight: milestone.status == MilestoneStatus.active
                  ? FontWeight.w800
                  : FontWeight.w500,
              fontSize: 10,
              color: milestone.status == MilestoneStatus.active
                  ? _maroon
                  : const Color(0xff98A2AD),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(double diameter) {
    final icon = _icon;
    switch (milestone.type) {
      case MilestoneType.weekly:
        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _color,
            border: Border.all(color: _borderColor, width: 2),
          ),
          child: icon != null ? Center(child: icon) : null,
        );
      // Monthly milestones are filtered out before reaching this widget
      // (see goal_timeline_screen.dart) - falls back to the plain circle
      // like daily/endGoal rather than needing its own shape at all.
      case MilestoneType.monthly:
      case MilestoneType.daily:
      case MilestoneType.endGoal:
        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color,
            border: Border.all(color: _borderColor, width: 2),
          ),
          child: icon != null ? Center(child: icon) : null,
        );
    }
  }
}
