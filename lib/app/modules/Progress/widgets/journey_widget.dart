import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/journey_image_model.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class JourneyWidget extends StatelessWidget {
  final JourneyImageModel? journeyImage;

  const JourneyWidget({super.key, this.journeyImage});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Before image
            Container(
              height: 200,
              width: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xffFEF6FB),
                image:
                    journeyImage != null &&
                        journeyImage!.beforeImageUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          journeyImage!.beforeImageUrl,
                        ),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage('assets/demo_image/home_6.jpg'),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 4),
            // After image
            Container(
              height: 200,
              width: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xffFEF6FB),
                image:
                    journeyImage != null &&
                        journeyImage!.afterImageUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          journeyImage!.afterImageUrl,
                        ),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage('assets/demo_image/home_6.jpg'),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        CustomText(
          text: journeyImage?.dayLabel ?? "Day 1",
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Color(0xff530630),
        ),
      ],
    );
  }
}
