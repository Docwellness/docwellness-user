import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

import 'journey_line_painter.dart';

/// One node on the timeline - a circle (bigger for weekly/monthly/end_goal,
/// a trophy for end_goal), colored by status, with its date label beneath.
/// Tapping opens MilestoneSheet (wired by the parent screen, not here - this
/// widget is purely presentational).
class MilestoneNode extends StatelessWidget {
  final Milestone milestone;
  final bool isDimmed;
  final VoidCallback onTap;

  const MilestoneNode({
    super.key,
    required this.milestone,
    required this.onTap,
    this.isDimmed = false,
  });

  static const _maroon = Color(0xff851653);
  static const _done = Color(0xff1F8A5B);
  static const _missed = Color(0xffD64545);

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
      case MilestoneStatus.missed:
        return _missed;
      case MilestoneStatus.active:
        return _maroon;
      case MilestoneStatus.upcoming:
        return Colors.white;
    }
  }

  Widget? get _icon {
    if (milestone.type == MilestoneType.endGoal) {
      return const Text('🏆', style: TextStyle(fontSize: 18));
    }
    if (milestone.status == MilestoneStatus.completed) {
      return const Icon(Icons.check, size: 12, color: Colors.white);
    }
    if (milestone.status == MilestoneStatus.missed) {
      return const Icon(Icons.priority_high, size: 12, color: Colors.white);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final diameter = _diameter;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDimmed ? 0.35 : 1,
        child: SizedBox(
          width: kMilestoneSpacing,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (milestone.status == MilestoneStatus.active)
                Container(
                  width: diameter + 10,
                  height: diameter + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _maroon.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(child: _dot(diameter)),
                )
              else
                _dot(diameter),
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
      ),
    );
  }

  Widget _dot(double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color,
        border: Border.all(
          color: milestone.status == MilestoneStatus.upcoming
              ? const Color(0xffE9C6DC)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: _icon != null ? Center(child: _icon) : null,
    );
  }
}
