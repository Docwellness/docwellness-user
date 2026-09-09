import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen "quote of the day" popup shown once per new quote, right after
/// the app opens (see QuotesController._maybeShowLatestQuoteDialog). Get.dialog
/// hands its pageBuilder the whole screen, so the BackdropFilter here blurs
/// whatever is behind it. Tapping the blurred area dismisses it; the card
/// swallows its own tap so reading it doesn't accidentally close it.
class QuoteOfTheDayDialog extends StatefulWidget {
  final String quoteText;
  final String textHi;
  final String textMr;
  final String author;
  final String category;
  final String imageUrl;

  const QuoteOfTheDayDialog({
    super.key,
    required this.quoteText,
    this.textHi = '',
    this.textMr = '',
    this.author = 'DocWellness',
    this.category = 'Wellness',
    this.imageUrl = '',
  });

  @override
  State<QuoteOfTheDayDialog> createState() => _QuoteOfTheDayDialogState();
}

class _QuoteOfTheDayDialogState extends State<QuoteOfTheDayDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _plum = Color(0xff851653);
  static const _pink = Color(0xff9F1561);
  static const _ink = Color(0xff5A2A44);
  static const _meta = Color(0xff9C6B85);

  @override
  Widget build(BuildContext context) {
    final ease = CurvedAnimation(parent: _c, curve: const Cubic(0.23, 1, 0.32, 1));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.back(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.42),
          alignment: Alignment.center,
          child: FadeTransition(
            opacity: ease,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(ease),
              child: GestureDetector(
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xffFFF4FA), Color(0xffF8DCEC)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xffF3D3E4)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 40,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.imageUrl.startsWith('http')) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: widget.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (_, __) => const AspectRatio(
                                    aspectRatio: 2.3,
                                    child: ColoredBox(color: Color(0xffF8DCEC)),
                                  ),
                                  errorWidget: (_, __, ___) => const AspectRatio(
                                    aspectRatio: 2.3,
                                    child: ColoredBox(color: Color(0xffF8DCEC)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ] else
                              Text(
                                '“',
                                style: TextStyle(
                                  fontSize: 72,
                                  height: 0.8,
                                  fontWeight: FontWeight.w700,
                                  color: _plum.withValues(alpha: 0.16),
                                ),
                              ),
                            if (widget.quoteText.trim().isNotEmpty)
                              _line(widget.quoteText, primary: true),
                            if (widget.textHi.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _line(widget.textHi),
                            ],
                            if (widget.textMr.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _line(widget.textMr),
                            ],
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _plum.withValues(alpha: 0.09),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    widget.category.toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: _pink,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    '— ${widget.author}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _meta,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(String s, {bool primary = false}) => Text(
    s,
    style: TextStyle(
      fontFamily: 'Roboto',
      fontSize: primary ? 17 : 14.5,
      height: 1.5,
      fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
      color: primary ? _ink : _ink.withValues(alpha: 0.8),
    ),
  );
}
