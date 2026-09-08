import 'dart:async';
import 'dart:math' as math;

import 'package:docwellness/app/modules/home/widgets/diet_countdown_text.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Home's "Your progress" card, for the days a subscription pause is
/// running. The calorie ring the patient normally sees here would be all
/// zeros - nothing to log, nothing consumed - which reads as broken. This
/// replaces it with the same ring footprint turned into a pause state: the
/// arc now tracks how far through the pause window today is, the centre
/// holds a slowly breathing pause glyph, and the resume date + a live
/// countdown sit below.
///
/// Motion (see the `animate` skill's gate): this card is seen a handful of
/// times across a multi-day pause - occasional, so a standard animation is
/// fine. Purpose is state indication: one continuous, low-amplitude "breath"
/// says the app is alive and resting, not stuck. All motion is
/// transform/opacity only and is dropped under `MediaQuery.disableAnimations`.
class PausedProgressCard extends StatefulWidget {
  final DateTime resumeDate;

  /// When the pause window began - used for the arc's elapsed/total ratio.
  /// Null falls back to an arc-less ring (just the breathing glyph).
  final DateTime? startDate;

  const PausedProgressCard({
    super.key,
    required this.resumeDate,
    this.startDate,
  });

  @override
  State<PausedProgressCard> createState() => _PausedProgressCardState();
}

class _PausedProgressCardState extends State<PausedProgressCard>
    with TickerProviderStateMixin {
  static const _accent = Color(0xff851653);
  static const _accentSoft = Color(0xffEF45B2);
  static const _track = Color(0xffF6D9EC);
  static const _muted = Color(0xff6C737F);

  // Continuous "breath" for the glyph + the sonar ring behind it. One
  // controller, gentle easeInOut, ~2.4s - slow enough to feel like resting,
  // not a spinner.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  // One-shot entrance: the arc sweeps to its real value, the content settles
  // up 8px and fades in.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  Timer? _tick;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce == _reduceMotion) {
      if (!reduce && !_enter.isCompleted && !_enter.isAnimating) {
        _enter.forward();
        _breath.repeat(reverse: true);
      }
      return;
    }
    _reduceMotion = reduce;
    if (reduce) {
      _breath.stop();
      _breath.value = 0.5; // mid-breath resting pose
      _enter.value = 1;
    } else {
      _enter.forward();
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _breath.dispose();
    _enter.dispose();
    super.dispose();
  }

  double? get _elapsedFraction {
    final start = widget.startDate;
    if (start == null) return null;
    final total = widget.resumeDate.difference(start).inSeconds;
    if (total <= 0) return null;
    final done = DateTime.now().difference(start).inSeconds;
    return (done / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final resumeLabel = DateFormat('d MMM yyyy').format(widget.resumeDate);
    final countdown = dietCountdownText(widget.resumeDate);
    final target = _elapsedFraction;

    return AnimatedBuilder(
      animation: Listenable.merge([_breath, _enter]),
      builder: (context, _) {
        // easeInOut breath, 0..1..0 via the reversing controller.
        final breath = Curves.easeInOut.transform(_breath.value);
        final enter = Curves.easeOutCubic.transform(_enter.value);
        final sweep = target == null ? null : target * enter;

        return Opacity(
          opacity: enter,
          child: Transform.translate(
            offset: Offset(0, (1 - enter) * 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                SizedBox(
                  width: 168,
                  height: 168,
                  child: CustomPaint(
                    painter: _PauseRingPainter(
                      progress: sweep,
                      pulse: _reduceMotion ? 0 : breath,
                      track: _track,
                      accent: _accent,
                      accentSoft: _accentSoft,
                    ),
                    child: Center(
                      child: Transform.scale(
                        // 0.94 <-> 1.0 breath - never from nothing.
                        scale: _reduceMotion ? 1 : 0.94 + 0.06 * breath,
                        child: _PauseGlyph(color: _accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const CustomText(
                  text: 'Plan paused',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
                const SizedBox(height: 6),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    text: 'Resumes ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _muted,
                    ),
                    children: [
                      TextSpan(
                        text: resumeLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xff530630),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFCE7F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pause_circle_filled_rounded,
                        size: 16,
                        color: _accent,
                      ),
                      const SizedBox(width: 6),
                      CustomText(
                        text: 'resumes in $countdown',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const CustomText(
                  text:
                      'Picks up right where it left off — nothing is skipped.',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: _muted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Two rounded bars - the universal pause mark, drawn rather than an icon
/// font so the two bars share an exact corner radius and gap at any scale.
class _PauseGlyph extends StatelessWidget {
  final Color color;
  const _PauseGlyph({required this.color});

  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(
          width: 9,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [bar(), const SizedBox(width: 7), bar()],
    );
  }
}

class _PauseRingPainter extends CustomPainter {
  /// 0..1 fraction of the pause elapsed; null = no arc, just the track.
  final double? progress;

  /// 0..1 breath phase, drives a faint expanding "sonar" ring.
  final double pulse;

  final Color track;
  final Color accent;
  final Color accentSoft;

  _PauseRingPainter({
    required this.progress,
    required this.pulse,
    required this.track,
    required this.accent,
    required this.accentSoft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 10.0;
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Sonar pulse: a ring that grows out past the track and fades. Reads as
    // a slow heartbeat behind the glyph.
    if (pulse > 0) {
      final t = pulse;
      final pulseRadius = radius + t * 18;
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accentSoft.withValues(alpha: 0.32 * (1 - t));
      canvas.drawCircle(center, pulseRadius, pulsePaint);
    }

    // Track.
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = track,
    );

    // Elapsed arc, from 12 o'clock, clockwise.
    final p = progress;
    if (p != null && p > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * p,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: 3 * math.pi / 2,
            colors: [accentSoft, accent],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_PauseRingPainter old) =>
      old.progress != progress ||
      old.pulse != pulse ||
      old.accent != accent;
}
