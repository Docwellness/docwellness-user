import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDropdown extends StatefulWidget {
  final String? label;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final double? lableSize;
  final double? horizontalSpace;
  final bool isRounded;
  final Color suffixIconColor;
  final String? hintText;

  final Icon? prefixIcon;
  final Icon? suffixIcon;

  const CustomDropdown({
    super.key,
    this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.lableSize,
    this.horizontalSpace,
    required this.isRounded,
    required this.suffixIconColor,
    this.hintText,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey<FormFieldState<String>> _formFieldKey =
      GlobalKey<FormFieldState<String>>();
  OverlayEntry? _barrierEntry;
  OverlayEntry? _listEntry;
  bool isOpen = false;

  @override
  void didUpdateWidget(covariant CustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // widget.value is this dropdown's real source of truth, but it can
    // change from outside a tap in this widget's own overlay (e.g. loaded
    // asynchronously once a saved request's data arrives) - without this,
    // the wrapped FormField's internal value falls out of sync with what's
    // actually displayed, so Form.validate() can report "required" on a
    // field that visibly has a selection. Deferred a frame since didChange
    // triggers setState, which isn't safe to call from didUpdateWidget.
    if (widget.value != oldWidget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _formFieldKey.currentState?.didChange(widget.value);
        }
      });
    }
  }

  void openDropdown(FormFieldState<String> state) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;

    // Full-screen, invisible, tap-to-dismiss barrier rendered BELOW the
    // option list but above the rest of the page. Without this, the overlay
    // had no way to know a tap landed elsewhere (e.g. another field) - it
    // would just stay open while focus silently moved on. The barrier
    // consumes that first outside tap (closing the dropdown) rather than
    // letting it fall through to whatever field is underneath, matching how
    // dropdowns/menus are expected to behave everywhere else.
    _barrierEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: closeDropdown,
        ),
      ),
    );

    _listEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, -(size.height + 6)),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: widget.items.map((item) {
                  return InkWell(
                    onTap: () {
                      widget.onChanged(item);
                      state.didChange(item);
                      closeDropdown();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        item,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: const Color(0xff530630),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insertAll([_barrierEntry!, _listEntry!]);
    setState(() => isOpen = true);
  }

  void closeDropdown() {
    _barrierEntry?.remove();
    _listEntry?.remove();
    _barrierEntry = null;
    _listEntry = null;
    if (mounted) {
      setState(() => isOpen = false);
    } else {
      isOpen = false;
    }
  }

  @override
  void dispose() {
    // Overlay entries outlive this State's widget tree position - remove any
    // still-open dropdown so it doesn't dangle after this field is disposed
    // (e.g. navigating away while the dropdown was left open).
    _barrierEntry?.remove();
    _listEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _formFieldKey,
      initialValue: widget.value,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.disabled,
      builder: (state) {
        bool hasText = widget.value != null && widget.value!.isNotEmpty;
        bool isFocused = isOpen;

        Color borderColor = (isFocused || hasText)
            ? const Color(0xff530630)
            : const Color(0xff6C737F);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                onTap: () => isOpen ? closeDropdown() : openDropdown(state),
                child: InputDecorator(
                  isFocused: isOpen,
                  isEmpty: !hasText,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: widget.horizontalSpace ?? 16,
                    ),

                    prefixIconConstraints: const BoxConstraints(
                      minHeight: 38,
                      minWidth: 38,
                      maxHeight: 38,
                      maxWidth: 38,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minHeight: 38,
                      minWidth: 38,
                      maxHeight: 38,
                      maxWidth: 38,
                    ),
                    hintText: widget.hintText,
                    hintStyle: GoogleFonts.roboto(
                      color: const Color(0xff4D5761),
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                    label: (isFocused || hasText)
                        ? widget.label != null
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
                                    text: widget.label!,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                    color: const Color(0xff851653),
                                  ),
                                )
                              : null
                        : widget.label == null
                        ? null
                        : Text(
                            widget.label!,
                            style: GoogleFonts.roboto(
                              fontSize: widget.lableSize ?? 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff4D5761),
                            ),
                          ),

                    prefixIcon: widget.prefixIcon,

                    suffixIcon:
                        widget.suffixIcon ??
                        (widget.isRounded == true
                            ? Icon(
                                isOpen
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: widget.suffixIconColor,
                              )
                            : Icon(
                                isOpen
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: widget.suffixIconColor,
                              )),

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
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),

                  child: Text(
                    widget.value ?? "",
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xff530630),
                    ),
                  ),
                ),
              ),
            ),

            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: Colors.red[900], fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
