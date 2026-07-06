import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/home/widgets/custom_portion_dropdown.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogMealContainer extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String garam;
  final String kcal;
  final int index;
  final String selectedPortion;
  final bool isPresentDate;
  final String servingTime;
  final String recipeId;

  const LogMealContainer({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.garam,
    required this.kcal,
    required this.index,
    required this.selectedPortion,
    required this.isPresentDate,
    required this.servingTime,
    required this.recipeId,
  });

  @override
  State<LogMealContainer> createState() => _LogMealContainerState();
}

class _LogMealContainerState extends State<LogMealContainer> {
  final DietController controller = Get.find<DietController>();
  late String selectedPortion;

  @override
  void initState() {
    super.initState();
    // Initialize from controller if already selected, else from widget
    selectedPortion = controller.selectedPortions["${widget.servingTime}-${widget.recipeId}"]?.toString() ??
        widget.selectedPortion;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          color: Color(0xffFEF6FB),
          border: Border.all(color: Color(0xffFDF2FA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(widget.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: widget.title,
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xff384250),
                  ),
                  Wrap(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: Color(0xffFCE7F6),
                          border: Border.all(color: Color(0xffEF45B2)),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: CustomText(
                          text: '${widget.garam} / 1 Bowl',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Color(0xff851653),
                        ),
                      ),
                      SizedBox(width: 4),
                      CustomText(
                        text: widget.kcal,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Color(0xff6C737F),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            SizedBox(
              width: 80,
              height: 40,
              child: CustomPortionDropDown(
                label: "Portion",
                value: selectedPortion,
                items: List.generate(100, (index) => '${index + 1}'),
                onChanged: (v) {
                  setState(() {
                    selectedPortion = v!;
                    if (int.parse(v) > 0) {
                      controller.selectedPortions["${widget.servingTime}-${widget.recipeId}"] =
                          int.parse(v);
                    } else {
                      controller.selectedPortions.remove("${widget.servingTime}-${widget.recipeId}");
                    }
                  });
                },
                isPresentDate: widget.isPresentDate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
