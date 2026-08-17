import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/home/widgets/custom_portion_dropdown.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/functions/quantity_label.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogMealContainer extends StatefulWidget {
  final String imageUrl;
  final String title;
  // Raw quantity only (e.g. "100", not "100G") - the badge below applies
  // the same tbsp/cup approximation the dietician app shows (see
  // quantity_label.dart), so `unit` must be passed separately.
  final String garam;
  final String unit;
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
    this.unit = '',
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
          border: cardBorder,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow,
        ),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: const Color(0xffFDF2FA),
                borderRadius: BorderRadius.circular(16),
                image: widget.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(widget.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
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
                          text: formatQuantityLabel(widget.garam, widget.unit),
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
                // 0 = not logged (the default for anything the patient
                // hasn't picked yet) - 1+ = how many portions they ate.
                items: List.generate(101, (index) => '$index'),
                onChanged: (v) {
                  setState(() {
                    selectedPortion = v!;
                    final newPortion = int.parse(v);
                    final key = "${widget.servingTime}-${widget.recipeId}";
                    final wasAlreadyLogged = (int.tryParse(widget.selectedPortion) ?? 0) > 0;
                    if (newPortion > 0) {
                      controller.selectedPortions[key] = newPortion;
                    } else if (wasAlreadyLogged) {
                      // Was already logged (server-side portion > 0) and
                      // just dropped back to 0 - explicitly keep a 0 in
                      // the submission so the backend actually un-logs it
                      // (see submitMealLog), instead of silently omitting
                      // it, which left the old logged entry untouched.
                      controller.selectedPortions[key] = 0;
                    } else {
                      // Never logged and still not selected - nothing to
                      // submit, no need to carry a 0 in the payload.
                      controller.selectedPortions.remove(key);
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
