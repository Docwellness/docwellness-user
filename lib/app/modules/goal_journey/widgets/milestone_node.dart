import 'package:docwellness/app/models/timeline_models.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

import 'heartbeat_pulse.dart';
import 'journey_line_painter.dart';

/// One node on the timeline, shaped by [Milestone.type] so the three
/// cadences read apart from each other at a glance without relying on
/// color/size alone: weekly is a rounded square, monthly is a triangle,
/// daily (and the trophy end-goal) stays a circle. Colored by status, with
/// its date label beneath. The active ("today") node also beats like a
/// heartbeat (see HeartbeatPulse) so it's unmistakable which one is current.
/// Tapping opens MilestoneSheet (wired by the parent screen, not here - this
/// widget is purely presentational).
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

  Color get _borderColor =>
      milestone.status == MilestoneStatus.upcoming ? const Color(0xffE9C6DC) : Colors.transparent;

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
                    ? HeartbeatPulse(
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
      case MilestoneType.monthly:
        return SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(diameter, diameter),
                painter: _TrianglePainter(color: _color, borderColor: _borderColor),
              ),
              // Nudged down from dead-center to sit inside the triangle's
              // visual mass (its centroid sits below the bounding box's
              // geometric center), not straddling the top point.
              if (icon != null) Padding(padding: const EdgeInsets.only(top: 7), child: icon),
            ],
          ),
        );
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

/// Fills + strokes an upward-pointing triangle within its bounding box -
/// Flutter has no built-in triangle shape, unlike BoxShape.circle/rectangle.
class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);

    if (borderColor != Colors.transparent) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}
