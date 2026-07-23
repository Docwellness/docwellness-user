import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Country data
// ---------------------------------------------------------------------------

class _Country {
  final String name;
  final String flag;
  final String dial; // without leading +

  const _Country(this.name, this.flag, this.dial);
}

const _kCountries = [
  // Popular first
  _Country('India', '🇮🇳', '91'),
  _Country('United States', '🇺🇸', '1'),
  _Country('United Kingdom', '🇬🇧', '44'),
  _Country('Canada', '🇨🇦', '1'),
  _Country('Australia', '🇦🇺', '61'),
  _Country('United Arab Emirates', '🇦🇪', '971'),
  _Country('Saudi Arabia', '🇸🇦', '966'),
  _Country('Pakistan', '🇵🇰', '92'),
  _Country('Bangladesh', '🇧🇩', '880'),
  _Country('Sri Lanka', '🇱🇰', '94'),
  _Country('Nepal', '🇳🇵', '977'),
  _Country('Singapore', '🇸🇬', '65'),
  _Country('Malaysia', '🇲🇾', '60'),
  _Country('Indonesia', '🇮🇩', '62'),
  _Country('Philippines', '🇵🇭', '63'),
  _Country('Thailand', '🇹🇭', '66'),
  _Country('South Korea', '🇰🇷', '82'),
  _Country('Japan', '🇯🇵', '81'),
  _Country('China', '🇨🇳', '86'),
  _Country('Germany', '🇩🇪', '49'),
  _Country('France', '🇫🇷', '33'),
  _Country('Italy', '🇮🇹', '39'),
  _Country('Spain', '🇪🇸', '34'),
  _Country('Netherlands', '🇳🇱', '31'),
  _Country('Sweden', '🇸🇪', '46'),
  _Country('Switzerland', '🇨🇭', '41'),
  _Country('Russia', '🇷🇺', '7'),
  _Country('Brazil', '🇧🇷', '55'),
  _Country('Mexico', '🇲🇽', '52'),
  _Country('Argentina', '🇦🇷', '54'),
  _Country('South Africa', '🇿🇦', '27'),
  _Country('Nigeria', '🇳🇬', '234'),
  _Country('Kenya', '🇰🇪', '254'),
  _Country('Egypt', '🇪🇬', '20'),
  _Country('Qatar', '🇶🇦', '974'),
  _Country('Kuwait', '🇰🇼', '965'),
  _Country('Bahrain', '🇧🇭', '973'),
  _Country('Oman', '🇴🇲', '968'),
  _Country('Jordan', '🇯🇴', '962'),
  _Country('New Zealand', '🇳🇿', '64'),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Telegram-style phone field:
/// [ 🇮🇳 +91 ▼ | number... ]
///
/// Writes the combined full number (+dialCode + digits) back into [controller].
class PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;

  const PhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.enabled = true,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late _Country _selected;
  final _numCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _focused = false;

  static const _primary = Color(0xff530630);
  static const _accent = Color(0xff851653);
  static const _border = Color(0xffEAD4E8);
  static const _label = Color(0xff4D5761);

  @override
  void initState() {
    super.initState();
    _selected = _kCountries.first; // default India

    // Parse existing value (e.g. "+919876543210")
    final existing = widget.controller.text.trim();
    if (existing.isNotEmpty) {
      // Try to match a known dial code (longest match first to avoid +1 vs +91)
      final sorted = [..._kCountries]
        ..sort((a, b) => b.dial.length.compareTo(a.dial.length));
      for (final c in sorted) {
        if (existing.startsWith('+${c.dial}')) {
          _selected = c;
          _numCtrl.text = existing.substring(c.dial.length + 1);
          break;
        }
      }
      if (_numCtrl.text.isEmpty) {
        _numCtrl.text = existing.replaceAll(RegExp(r'^\+?\d{1,4}'), '');
      }
    }

    _numCtrl.addListener(_sync);
    _focusNode.addListener(
      () => setState(() => _focused = _focusNode.hasFocus),
    );
  }

  void _sync() {
    widget.controller.text = '+${_selected.dial}${_numCtrl.text.trim()}';
  }

  @override
  void dispose() {
    _numCtrl.removeListener(_sync);
    _numCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    String query = '';
    List<_Country> filtered = _kCountries;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              builder: (_, scrollCtrl) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      const Text(
                        'Select Country',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1F2A37),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Search
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search country or code',
                            hintStyle: const TextStyle(
                              color: Color(0xff9CA3AF),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xff9CA3AF),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xffF9F5FC),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _accent,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (v) {
                            query = v.toLowerCase();
                            setModal(() {
                              filtered = _kCountries
                                  .where(
                                    (c) =>
                                        c.name.toLowerCase().contains(query) ||
                                        c.dial.contains(query),
                                  )
                                  .toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final c = filtered[i];
                            final isSelected =
                                c.dial == _selected.dial &&
                                c.name == _selected.name;
                            // Wrapped in its own Material - the sheet's
                            // outer Container sets an explicit background
                            // color (white), which otherwise sits between
                            // this ListTile and the nearest Material
                            // ancestor and hides its ink splash (this fired
                            // in production on every single row of this
                            // ~200-country list - Sentry: FlutterError:
                            // ListTile background color or ink splashes may
                            // be invisible).
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                leading: Text(
                                  c.flag,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                title: Text(
                                  c.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isSelected
                                        ? _primary
                                        : const Color(0xff1F2A37),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                trailing: Text(
                                  '+${c.dial}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected
                                        ? _accent
                                        : const Color(0xff6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  setState(() => _selected = c);
                                  _sync();
                                  Navigator.pop(ctx);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: (v) {
        final combined = widget.controller.text;
        if (widget.validator != null) return widget.validator!(combined);
        if (_numCtrl.text.trim().isEmpty) return 'Enter WhatsApp number';
        if (_numCtrl.text.trim().length < 6) return 'Enter valid number';
        return null;
      },
      builder: (state) {
        final hasFocus = _focused;
        final hasText = _numCtrl.text.trim().isNotEmpty;

        // Matches CustomField's OutlineInputBorder exactly: same
        // radius/colors/static width, so the phone field's border reads as
        // the same field style as every other field on this form (Full
        // Name, Weight, Height, Email, etc.) rather than its own variant.
        final borderColor = (hasFocus || hasText)
            ? _primary
            : const Color(0xff6C737F);
        const borderWidth = 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Row(
                children: [
                  // ── COUNTRY CODE BUTTON ──────────────────────────────
                  GestureDetector(
                    onTap: widget.enabled ? _showCountryPicker : null,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selected.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+${_selected.dial}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1F2A37),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: widget.enabled
                                ? _label
                                : Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── DIVIDER ──────────────────────────────────────────
                  Container(width: 1, height: 28, color: _border),

                  // ── NUMBER INPUT ─────────────────────────────────────
                  Expanded(
                    child: TextField(
                      controller: _numCtrl,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => state.didChange(widget.controller.text),
                      decoration: const InputDecoration(
                        hintText: 'Phone number',
                        hintStyle: TextStyle(
                          color: Color(0xff9CA3AF),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xff1F2A37),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── LABEL (floating look) ─────────────────────────────────
            // Show error message if any
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
