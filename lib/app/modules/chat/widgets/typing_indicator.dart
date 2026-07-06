import 'package:flutter/material.dart';

/// Telegram-style animated typing indicator with bouncing dots
class TypingIndicator extends StatefulWidget {
  final Color dotColor;
  final double dotSize;
  final String? typingText;
  final String? avatarInitial;

  const TypingIndicator({
    super.key,
    this.dotColor = const Color(0xff851653),
    this.dotSize = 8.0,
    this.typingText,
    this.avatarInitial,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Start animations with staggered delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar circle
          if (widget.avatarInitial != null)
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xffFCE7F6),
              child: Text(
                widget.avatarInitial!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff851653),
                ),
              ),
            ),
          if (widget.avatarInitial != null) const SizedBox(width: 8),

          // Typing bubble with bouncing dots
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xffFCE7F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return _BouncingDot(
                  animation: _animations[index],
                  dotColor: widget.dotColor,
                  dotSize: widget.dotSize,
                  isLast: index == 2,
                );
              }),
            ),
          ),

          if (widget.typingText != null) ...[
            const SizedBox(width: 8),
            Text(
              widget.typingText!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BouncingDot extends AnimatedWidget {
  final Color dotColor;
  final double dotSize;
  final bool isLast;

  const _BouncingDot({
    required Animation<double> animation,
    required this.dotColor,
    required this.dotSize,
    this.isLast = false,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Container(
      margin: EdgeInsets.only(right: isLast ? 0 : 4),
      child: Transform.translate(
        offset: Offset(0, -4 * animation.value),
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: dotColor.withOpacity(0.4 + (0.6 * animation.value)),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
