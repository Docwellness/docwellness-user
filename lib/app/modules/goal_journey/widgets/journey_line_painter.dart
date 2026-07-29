import 'package:docwellness/app/models/timeline_models.dart';
import 'package:flutter/material.dart';

/// Horizontal spacing between adjacent milestone node centers - shared with
/// goal_timeline_screen.dart's auto-scroll-to-today/focus math, so the
/// painted line and the node Row it sits under always agree on layout.
const double kMilestoneSpacing = 72.0;

/// Fixed height of every node's dot area (MilestoneNode centers its circle
/// within exactly this height, regardless of the circle's own diameter -
/// 16px for a plain daily dot up to 40px for the end-goal trophy, plus a
/// +10px active-state ring on whichever node is "today"). Without this, a
/// Row of differently-sized circles centers each by its own total bounding
/// box, so circle *centers* silently drift out of alignment with each other
/// and with wherever this painter draws its line.
const double kNodeDotAreaHeight = 54.0;

/// Draws the connecting line beneath a Row of MilestoneNode widgets - one
/// straight segment per adjacent pair, colored by the earlier node's status
/// (done segments solid green, everything else a soft rose). Styled after
/// this app's one existing CustomPainter (_FullCirclePainter in
/// home/widgets/progress_card.dart): rounded stroke caps, colors passed in
/// rather than hardcoded, externally-driven data (no internal
/// AnimationController).
class JourneyLinePainter extends CustomPainter {
  final List<MilestoneStatus> statuses;
  final double centerY;

  JourneyLinePainter({required this.statuses, required this.centerY});

  static const _doneColor = Color(0xff1F8A5B);
  static const _baseColor = Color(0xffFCE7F6);

  @override
  void paint(Canvas canvas, Size size) {
    if (statuses.length < 2) return;

    final basePaint = Paint()
      ..color = _baseColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final donePaint = Paint()
      ..color = _doneColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < statuses.length - 1; i++) {
      final startX = kMilestoneSpacing * i + kMilestoneSpacing / 2;
      final endX = kMilestoneSpacing * (i + 1) + kMilestoneSpacing / 2;
      final isDoneSegment = statuses[i] == MilestoneStatus.completed;
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(endX, centerY),
        isDoneSegment ? donePaint : basePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant JourneyLinePainter oldDelegate) =>
      oldDelegate.statuses != statuses || oldDelegate.centerY != centerY;
}
