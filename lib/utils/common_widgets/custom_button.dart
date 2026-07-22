import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final bool isOutline;
  final VoidCallback onTap;
  final double? fontSize;
  final Color? buttonColor;
  final Color? outlineButtonColor;
  final Color? textColor;
  final bool? isLoading;
  // Defaults true so every existing call site (none of which pass this) is
  // unaffected - opt in per-screen where a form has hard preconditions
  // (e.g. payment_status_sheet.dart's mandatory-fields gate).
  final bool enabled;

  const CustomButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.isOutline,
    this.buttonColor,
    this.fontSize,
    this.outlineButtonColor,
    this.textColor,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = enabled == false && isLoading != true;
    return GestureDetector(
      onTap: (isLoading == true || isDisabled) ? () {} : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: isOutline == true
                  ? outlineButtonColor ?? Color(0xff530630)
                  : Colors.transparent,
            ),
            color: isOutline == true
                ? Colors.transparent
                : buttonColor ?? Color(0xff530630),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: isLoading == true
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isOutline == true
                          ? textColor ?? Color(0xff530630)
                          : Colors.white,
                    ),
                  )
                : CustomText(
                    text: text,
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize ?? 16,
                    color: isOutline == true
                        ? textColor ?? Color(0xff530630)
                        : Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}
