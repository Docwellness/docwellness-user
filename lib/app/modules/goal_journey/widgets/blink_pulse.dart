import 'package:flutter/material.dart';

/// Wraps [child] with a soft glowing ring that continuously blinks outward
/// from behind it and fades - two rings staggered half a cycle apart so a
/// new one starts right as the other finishes, giving a continuous "live"
/// blink rather than a single pulse-then-pause. Matches the reference
/// design's "today" node treatment (a solid dot with a soft radiating glow)
/// on both the Goal Journey timeline's active node and Home's mini
/// day-strip today dot.
class BlinkPulse extends StatefulWidget {
  final Widget child;
  final Color color;

  const BlinkPulse({super.key, required this.child, this.color = const Color(0xffDE2493)});

  @override
  State<BlinkPulse> createState() => _BlinkPulseState();
}

class _BlinkPulseState extends State<BlinkPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => CustomPaint(
        painter: _BlinkRingPainter(progress: _controller.value, color: widget.color),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _BlinkRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BlinkRingPainter({required this.progress, required this.color});

  static const _staggerPhases = [0.0, 0.5];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide / 2;

    for (final phase in _staggerPhases) {
      final t = (progress + phase) % 1.0;
      final radius = baseRadius + t * baseRadius * 0.9;
      final opacity = (1 - t).clamp(0.0, 1.0) * 0.45;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BlinkRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
