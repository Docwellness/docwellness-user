import 'dart:async';

import 'package:docwellness/app/modules/home/widgets/diet_countdown_text.dart';
import 'package:docwellness/app/modules/home/widgets/diet_info_actions.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Shown instead of the Diet & Exercise content while the dietician has
/// paused this patient's subscription and today is inside the pause window.
/// Logging is disabled everywhere (the backend also 403s); the plan picks
/// up exactly where it left off once [resumeDate] arrives. Mirrors
/// DietStartsSoonWidget's shape (embedded vs standalone, minute-tick
/// countdown).
class SubscriptionPausedWidget extends StatefulWidget {
  final DateTime resumeDate;
  final bool embedded;

  const SubscriptionPausedWidget({
    super.key,
    required this.resumeDate,
    this.embedded = false,
  });

  @override
  State<SubscriptionPausedWidget> createState() =>
      _SubscriptionPausedWidgetState();
}

class _SubscriptionPausedWidgetState extends State<SubscriptionPausedWidget> {
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
    if (widget.embedded) return _body();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Text(
          "Diet Plan",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            color: const Color(0xff1F2A37),
          ),
        ),
      ),
      body: _body(),
      bottomNavigationBar: const DietInfoActions(),
    );
  }

  Widget _body() {
    final resumeLabel = DateFormat('d MMM yyyy').format(widget.resumeDate);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 43),
          const Icon(Icons.pause_circle_outline,
              size: 96, color: Color(0xff851653)),
          const SizedBox(height: 40),
          const CustomText(
            text: "Your plan is paused",
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xff851653),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xffFEF6FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffFCE7F6)),
            ),
            child: CustomText(
              text: "Resumes $resumeLabel  ·  ${dietCountdownText(widget.resumeDate)}",
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xff851653),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 13),
          const CustomText(
            text:
                "Logging is paused for now. Your diet and exercise plan will pick up right where it left off when it resumes.",
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xff4D5761),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
