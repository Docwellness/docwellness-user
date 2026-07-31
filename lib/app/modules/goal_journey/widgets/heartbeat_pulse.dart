import 'package:flutter/material.dart';

/// Wraps [child] in a continuously repeating heartbeat-style pulse - a quick
/// "lub-dub" double-beat followed by a rest, roughly matching a resting
/// heart rate, rather than a generic single up-down pulse. Used to mark
/// "today" wherever it shows up (the Goal Journey timeline's active node,
/// Home's mini day-strip today dot) so it visibly reads as live/current
/// instead of just another static dot.
class HeartbeatPulse extends StatefulWidget {
  final Widget child;

  const HeartbeatPulse({super.key, required this.child});

  @override
  State<HeartbeatPulse> createState() => _HeartbeatPulseState();
}

class _HeartbeatPulseState extends State<HeartbeatPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _scale = TweenSequence<double>([
      // "Lub" - the bigger beat.
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.22).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 12,
      ),
      // "Dub" - the smaller follow-up beat.
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.12).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      // Rest between beats.
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 56),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}
