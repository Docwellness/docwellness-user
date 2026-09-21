import 'package:flutter/material.dart';

/// A hand-rolled loading skeleton block - a soft light band sweeps left to
/// right across a rose-tinted placeholder, on loop. Used instead of a bare
/// spinner so a slow load still reads as "content is coming" and roughly
/// previews the page's shape.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: Stack(
          children: [
            Container(color: const Color(0xffFCE7F6)),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : 300.0;
                    final dx = -w + (_controller.value * 2 * w);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Container(
                        width: w * 0.55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffFCE7F6).withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.9),
                              const Color(0xffFCE7F6).withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
