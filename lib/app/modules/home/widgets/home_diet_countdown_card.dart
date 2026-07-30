import 'dart:async';

import 'package:docwellness/app/modules/home/widgets/diet_countdown_text.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

/// Compact "diet plan starts in X" row shown below the BMI card on Home
/// while dietEnabled is false and a plan with a future start date exists
/// (see HomeController._refreshDietGate). Ticks its own text every minute,
/// independent of Home's own data-refresh cadence - Home's auto-refresh
/// polling stops once the request status is terminal (Paid etc, the
/// common case here), so this can't rely on a parent rebuild to stay live.
class HomeDietCountdownCard extends StatefulWidget {
  final DateTime startDate;

  const HomeDietCountdownCard({super.key, required this.startDate});

  @override
  State<HomeDietCountdownCard> createState() => _HomeDietCountdownCardState();
}

class _HomeDietCountdownCardState extends State<HomeDietCountdownCard> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            color: Color(0xff851653),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              text: 'Diet plan starts in ${dietCountdownText(widget.startDate)}',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xff851653),
            ),
          ),
        ],
      ),
    );
  }
}
