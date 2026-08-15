import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen "quote of the day" popup shown once per new quote, right
/// after the app opens (see QuotesController._maybeShowLatestQuoteDialog).
/// Get.dialog hands its pageBuilder the whole screen (unlike showDialog's
/// centered Material Dialog box), so BackdropFilter here blurs whatever
/// screen is sitting behind it. Tapping that blurred area dismisses it; the
/// card itself swallows its own tap so reading it doesn't accidentally
/// close it.
class QuoteOfTheDayDialog extends StatelessWidget {
  final String imageUrl;
  final String quoteText;

  const QuoteOfTheDayDialog({
    super.key,
    required this.imageUrl,
    required this.quoteText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.back(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.45),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 260,
                        width: 260,
                        color: Colors.white.withOpacity(0.15),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 260,
                        width: 260,
                        color: Colors.white.withOpacity(0.15),
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  if (quoteText.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    CustomText(
                      text: quoteText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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
    );
  }
}
