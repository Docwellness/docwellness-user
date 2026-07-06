import 'package:docwellness/app/models/active_diet_plan_model.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';

class CookingStepsTab extends StatefulWidget {
  final Recipe recipe;
  final List<String>? translatedSteps;

  const CookingStepsTab({
    super.key,
    required this.recipe,
    this.translatedSteps,
  });

  @override
  State<CookingStepsTab> createState() => _CookingStepsTabState();
}

class _CookingStepsTabState extends State<CookingStepsTab> {
  int selectedCount = 0;

  List<String> get steps =>
      widget.translatedSteps ?? widget.recipe.instructions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final isSelected = selectedCount == index;
              final data = steps[index];

              return Padding(
                padding: const EdgeInsets.only(left: 9, right: 9),
                child: Column(
                  children: [
                    Divider(color: Color(0xffFCCEEF), thickness: 0.6),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 16,
                        top: 7,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCount = index;
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                border: isSelected
                                    ? Border.all(
                                        color: Color(0xff851653),
                                        width: 2,
                                      )
                                    : null,
                                color: Color(0xffFCE7F6),
                                borderRadius: BorderRadius.circular(64),
                              ),
                              child: Center(
                                child: CustomText(
                                  text: "${index + 1}",

                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff851653),
                                ),
                              ),
                            ),

                            SizedBox(width: 16),
                            Expanded(
                              child: CustomText(
                                text: data,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff384250),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomButton(
              fontSize: 14,
              onTap: () {},
              text: 'Share cooking steps',
              isOutline: false,
            ),
          ),

          SizedBox(height: 30),
        ],
      ),
    );
  }
}
