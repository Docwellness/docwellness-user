import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String description;
  final String tag;
  final String calories;
  final String image;

  const RecipeCard({
    super.key,
    required this.title,
    required this.description,
    required this.tag,
    required this.calories,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // LEFT COLOR BOX (instead of image)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // RIGHT CONTENT
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,

                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff1F2A37),
                  ),
                  SizedBox(height: 4),

                  CustomText(
                    text: description,

                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff4D5761),
                    height: 1.4,
                  ),

                  SizedBox(height: 16),

                  CustomText(
                    text: "$tag • $calories",

                    fontSize: 11,
                    color: Color(0xff4D5761),
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
