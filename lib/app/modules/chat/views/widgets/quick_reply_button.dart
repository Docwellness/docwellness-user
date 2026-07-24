import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickReplyButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSelected;

  const QuickReplyButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Semantics + a 48px minimum tap target (AI_EXECUTION_PLAN.md Phase 6,
    // P6-09) - the visible pill stays its normal compact size (these are
    // auxiliary quick-reply suggestions in a Wrap, not primary CTAs, so
    // visually ballooning them to 48px would look wrong), but the actual
    // hit area is guaranteed to be at least 48px tall via minHeight, and a
    // screen reader now gets a button role + label at all (previously a
    // bare GestureDetector, same gap as CustomButton's).
    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xffFCE7F6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xffFCE7F6),
                width: 1.5,
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xff851653),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuickReplyRow extends StatelessWidget {
  final List<String> replies;
  final Function(String) onReplyTap;

  const QuickReplyRow({
    super.key,
    required this.replies,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: replies
            .map((reply) => QuickReplyButton(
                  text: reply,
                  onTap: () => onReplyTap(reply),
                ))
            .toList(),
      ),
    );
  }
}
