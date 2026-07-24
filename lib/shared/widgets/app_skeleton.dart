import 'package:flutter/material.dart';
import 'package:docwellness/core/theme/app_colors.dart';
import 'package:docwellness/core/theme/app_radius.dart';

/// Reusable shimmering placeholder block - AI_EXECUTION_PLAN.md Phase 6,
/// P6-02. No new shimmer-animation dependency added (the app has no
/// existing one) - a simple pulsing opacity via AnimatedOpacity keeps this
/// self-contained.
class AppSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> {
  bool _dim = false;

  @override
  void initState() {
    super.initState();
    _pulse();
  }

  void _pulse() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _dim = !_dim);
      _pulse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      opacity: _dim ? 0.4 : 1.0,
      child: Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: widget.borderRadius ?? AppRadius.smRadius,
        ),
      ),
    );
  }
}
