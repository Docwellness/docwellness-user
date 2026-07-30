import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/modules/Progress/controllers/progress_controller.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientJourneySection extends StatelessWidget {
  final bool? titleReruired;
  const ClientJourneySection({super.key, this.titleReruired = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProgressController(), permanent: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titleReruired == true)
          CustomText(
            text: "Client's journey",
            fontWeight: FontWeight.w400,
            color: const Color(0xff530630),
            fontSize: 17,
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 270,
          child: Obx(() {
            if (controller.isJourneyLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            // Use auto-generated milestone cards (from body logs), fallback to manual
            final cards = controller.autoJourneyCards.isNotEmpty
                ? controller.autoJourneyCards
                : controller.journeyImages;
            if (cards.isEmpty) {
              return Center(
                child: CustomText(
                  text: "No journey images yet",
                  fontSize: 13,
                  color: const Color(0xff49454F),
                  fontWeight: FontWeight.w400,
                ),
              );
            }
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final image = cards[index];
                final hasAfter = image.afterImageUrl.isNotEmpty;
                return Container(
                  width: hasAfter ? 340 : 220,
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF6FB),
                    borderRadius: BorderRadius.circular(12),
                    border: cardBorder,
                    boxShadow: cardShadow,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                image: image.beforeImageUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          image.beforeImageUrl,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: image.beforeImageUrl.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Before',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff49454F),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          // Only show after box when there is an after image
                          if (image.afterImageUrl.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      image.afterImageUrl,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      CustomText(
                        text: image.dayLabel,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff530630),
                        fontSize: 13,
                      ),
                      if (image.description.isNotEmpty)
                        CustomText(
                          text: image.description,
                          fontSize: 11,
                          color: const Color(0xff49454F),
                          fontWeight: FontWeight.w400,
                        ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
