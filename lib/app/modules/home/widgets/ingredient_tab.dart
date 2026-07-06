import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class IngredientTile extends StatelessWidget {
  final String image;
  final String name;
  final String gram;
  const IngredientTile({super.key, required this.image, required this.name, required this.gram});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
      child: Column(
        children: [
          SizedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Placeholder
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: name,

                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff384250),

                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 10),
                      CustomText(
                        text: "Protein Rich • ₹₹ • $gram ",

                        color: Color(0xff6C737F),
                        fontWeight: FontWeight.w400,
                        fontSize: 13,

                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 1),
                      CustomText(
                        text:
                            "Supporting line text lorem ipsum dolor sit amet, consectetur.",

                        color: Color(0xff6C737F),
                        fontWeight: FontWeight.w400,

                        fontSize: 13,

                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Divider(thickness: 0.7, color: Color(0xffFCCEEF)),
        ],
      ),
    );
  }
}
