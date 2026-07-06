import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomField extends StatefulWidget {
  final String? lable;
  final String? Function(String?)? validator;
  final void Function(String?)? onChange;

  final Icon? suffixIcon;
  final Widget? prefixIcon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool? isPhoneNumber;
  final bool? hide;
  final String? hintText;
  final int? maxLines;
  final bool? changeBorderColor;
  final bool? isPoint;
  final bool? space;

  const CustomField({
    super.key,
    this.validator,
    this.lable,
    required this.controller,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.isPhoneNumber = false,
    this.hide = false,
    this.hintText,
    this.maxLines,
    this.changeBorderColor = true,
    this.onChange,
    this.isPoint = false,
    this.space = true,
  });

  @override
  State<CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<CustomField> {
  final FocusNode _focusNode = FocusNode();
  late final VoidCallback _controllerListener;
  late final VoidCallback _focusListener;

  @override
  void initState() {
    super.initState();

    _focusListener = () {
      if (mounted) setState(() {});
    };
    _controllerListener = () {
      if (mounted) setState(() {});
    };
    _focusNode.addListener(_focusListener);
    widget.controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusListener);
    widget.controller.removeListener(_controllerListener);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFocused = _focusNode.hasFocus;
    bool hasText = widget.controller.text.isNotEmpty;

    Color borderColor = (isFocused || hasText)
        ? widget.changeBorderColor == true
              ? const Color(0xff530630)
              : Color(0xff6C737F)
        : const Color(0xff6C737F);

    return TextFormField(
      onChanged: widget.onChange,
      maxLines: widget.maxLines ?? 1,
      obscureText: widget.hide!,
      maxLength: widget.isPhoneNumber == true ? 15 : null,

      inputFormatters: [
        if (widget.keyboardType == TextInputType.phone)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
        if (widget.isPoint == true &&
            widget.keyboardType == TextInputType.number)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),

        if (widget.isPoint == false &&
            widget.keyboardType == TextInputType.number)
          FilteringTextInputFormatter.digitsOnly,
        if (widget.isPoint == false &&
            widget.keyboardType == TextInputType.text)
          FilteringTextInputFormatter.allow(RegExp(r'[a-z A-Z]')),
        if (widget.isPoint == false &&
            widget.keyboardType == TextInputType.emailAddress)
          FilteringTextInputFormatter.deny(' '),
        if (widget.space == false) FilteringTextInputFormatter.deny(' '),
      ],
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onTapOutside: (event) => FocusScope.of(context).unfocus(),
      cursorColor: Color(0xff530630),
      cursorErrorColor: Color(0xff530630),
      controller: widget.controller,

      style: GoogleFonts.roboto(
        color: const Color(0xff530630),
        fontWeight: FontWeight.w400,
        fontSize: 13,
      ),
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: GoogleFonts.roboto(
          color: const Color(0xff4D5761),
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        alignLabelWithHint: true,

        counterText: '',
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),

        label: (isFocused || hasText)
            ? widget.lable != null
                  ? Container(
                      height: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF6FB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: CustomText(
                        text: widget.lable!,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: const Color(0xff851653),
                      ),
                    )
                  : null
            : widget.lable == null
            ? null
            : Text(
                widget.lable!,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,

                  color: Color(0xff4D5761),
                ),
              ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: borderColor),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: borderColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: borderColor),
        ),
        prefix: widget.prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 0),
                child: widget.prefixIcon,
              ),

        suffixIcon: widget.suffixIcon,
      ),
    );
  }
}
