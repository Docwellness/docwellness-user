import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/modules/home/controllers/quotes_controller.dart';
import 'package:docwellness/app/modules/home/views/image_viewer.dart';
import 'package:docwellness/app/modules/home/views/motivation_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuotesSection extends StatefulWidget {
  const QuotesSection({super.key});

  @override
  State<QuotesSection> createState() => _QuotesSectionState();
}

class _QuotesSectionState extends State<QuotesSection> {
  final QuotesController _controller = Get.isRegistered<QuotesController>()
      ? Get.find<QuotesController>()
      : Get.put(QuotesController(), permanent: true);

  // Fallback images when API returns empty
  static const List<String> fallbackImages = [
    'assets/demo_image/home_3.png',
    'assets/demo_image/home_4.png',
    'assets/demo_image/home_3.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = _controller.isLoading.value;
      final quotes = _controller.quotes;
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Get.to(() => MotivationScreen()),
          child: Row(
            children: [
              CustomText(
                text: 'Quotes',
                fontWeight: FontWeight.w400,
                fontSize: 17,
                color: Color(0xff530630),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, color: Color(0xff530630), size: 18),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 137,
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xff851653)),
                )
              : quotes.isEmpty
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: fallbackImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Get.to(() => MotivationScreen()),
                      child: Container(
                        width: 132.97,
                        decoration: BoxDecoration(
                          color: Color(0xffFDF2FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Container(
                            height: 120,
                            width: 116.97,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(fallbackImages[index]),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: quotes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (context, index) {
                    final imageUrl = quotes[index]['imageUrl'] as String? ?? '';
                    final quoteText = quotes[index]['text'] as String? ?? '';
                    return GestureDetector(
                      onTap: () {
                        if (imageUrl.isNotEmpty) {
                          Get.to(
                            () => ImageViewer(
                              title: 'Quote',
                              subTitle: quoteText,
                              image: imageUrl,
                              isNetwork: true,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 132.97,
                        decoration: BoxDecoration(
                          color: Color(0xffFDF2FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: 120,
                                    width: 116.97,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => SizedBox(
                                      height: 120,
                                      width: 116.97,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xff851653),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      height: 120,
                                      width: 116.97,
                                      color: Color(0xffFDF2FA),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Color(0xff9DA4AE),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 120,
                                    width: 116.97,
                                    color: Color(0xffFDF2FA),
                                    child: Icon(
                                      Icons.format_quote,
                                      color: Color(0xff9DA4AE),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
      );
    });
  }
}
