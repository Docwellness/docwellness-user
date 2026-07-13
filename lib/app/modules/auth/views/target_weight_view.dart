import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/app/modules/auth/views/activity_level_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:docwellness/utils/functions/goal_weight_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TargetWeightView extends StatelessWidget {
  TargetWeightView({super.key});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final AuthController controller = Get.find<AuthController>();
  late final TextEditingController _targetWeightTextController =
      TextEditingController(
        text: controller.selectedTargetWeight.value.isNotEmpty
            ? controller.selectedTargetWeight.value.replaceAll(
                RegExp(r'[^0-9.]'),
                '',
              )
            : '',
      );

  double? _parsePositiveDouble(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double? _parseTargetWeight(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  ({double minKg, double maxKg, double heightCm})? _healthyRangeFromHeight() {
    final heightCm = _parsePositiveDouble(controller.heightController.text);
    if (heightCm == null) {
      return null;
    }

    final heightM = heightCm / 100;
    final minKg = 18.5 * heightM * heightM;
    final maxKg = 25 * heightM * heightM;

    return (minKg: minKg, maxKg: maxKg, heightCm: heightCm);
  }

  // Always just the current weight pulled into the healthy band - kept as
  // its own function (rather than inlined) since it's shown separately from
  // the quick-pick chips as the single "suggested" value.
  int? _suggestedTargetKg({
    required double currentWeight,
    required double minKg,
    required double maxKg,
  }) {
    if (currentWeight <= 0) {
      return null;
    }
    return currentWeight.clamp(minKg, maxKg).round();
  }

  /// The [lowest, highest] kg band quick-pick suggestions are spread across,
  /// anchored to the user's current weight and goal so every suggestion is
  /// consistent with the chosen goal:
  ///  - Weight Loss / Fat Loss: between the healthy floor (minKg) and
  ///    current weight - never suggests losing to a weight above where they
  ///    already are.
  ///  - Weight Gain: between current weight and the healthy ceiling (maxKg)
  ///    - never suggests gaining to a weight below where they already are.
  ///  - Weight Maintenance / Muscle Gain (Body Recomposition): a narrow band
  ///    centered on current weight, since the goal is to stay close to it
  ///    (recomposition allows a little more room to account for muscle
  ///    gain).
  ///  - Healthy Weight Management (or current weight not entered yet): the
  ///    full Normal-BMI band.
  /// Every bound is clamped to [minKg, maxKg], so suggestions never fall in
  /// the Overweight or Obese range.
  ({double lowest, double highest}) _bandForGoal({
    required String goal,
    required double minKg,
    required double maxKg,
    required double currentWeight,
  }) {
    if (currentWeight <= 0) {
      return (lowest: minKg, highest: maxKg);
    }
    switch (goal) {
      case 'Weight Loss':
      case 'Fat Loss':
        return (lowest: minKg, highest: currentWeight.clamp(minKg, maxKg));
      case 'Weight Gain':
        return (lowest: currentWeight.clamp(minKg, maxKg), highest: maxKg);
      case 'Weight Maintenance':
      case 'Muscle Gain (Body Recomposition)':
        final center = currentWeight.clamp(minKg, maxKg);
        return (
          lowest: (center - 3).clamp(minKg, maxKg),
          highest: (center + 3).clamp(minKg, maxKg),
        );
      case 'Healthy Weight Management':
      default:
        return (lowest: minKg, highest: maxKg);
    }
  }

  List<int> _quickPickWeights({
    required double minKg,
    required double maxKg,
    required String goal,
    required double currentWeight,
  }) {
    final band = _bandForGoal(
      goal: goal,
      minKg: minKg,
      maxKg: maxKg,
      currentWeight: currentWeight,
    );
    final lowest = band.lowest;
    final highest = band.highest;

    // Plain .round() can round a boundary value OUTWARD (e.g. round(53.3) ==
    // 53, which is below a 53.3 healthy floor) - that would suggest a weight
    // that's no longer BMI-Normal. Round inward instead: never below
    // ceil(minKg), never above floor(maxKg), so every suggestion is
    // guaranteed to stay inside the healthy range.
    final safeMinInt = minKg.ceil();
    final safeMaxInt = maxKg.floor();
    int toHealthyInt(double v) {
      final rounded = v.round();
      if (safeMaxInt < safeMinInt) {
        // Healthy band spans less than 1kg - no integer can satisfy the
        // constraint exactly; fall back to nearest integer.
        return rounded;
      }
      return rounded.clamp(safeMinInt, safeMaxInt);
    }

    if (highest <= lowest) {
      final fallback = <int>{toHealthyInt(lowest), toHealthyInt(highest)};
      return (fallback.toList()..sort());
    }

    final step = (highest - lowest) / 3;
    final values = <int>{
      toHealthyInt(lowest),
      toHealthyInt(lowest + step),
      toHealthyInt(lowest + 2 * step),
      toHealthyInt(highest),
    };

    return values.toList()..sort();
  }

  String _heightLabel(double heightCm) {
    if (heightCm % 1 == 0) {
      return heightCm.toStringAsFixed(0);
    }
    return heightCm.toStringAsFixed(1);
  }

  void _applyTargetWeight(int kg) {
    final value = kg.toString();
    _targetWeightTextController.text = value;
    _targetWeightTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    controller.setTargetWeight('$value kg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: 'What is your target weight?',
          fontWeight: FontWeight.w400,
          fontSize: 20,
          color: Color(0xff851653),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              SizedBox(height: 40),

              /// -------------------- TEXT INPUT --------------------
              CustomField(
                keyboardType: TextInputType.number,
                lable: 'Target Weight (in KG)',
                hintText: 'Enter your target weight',
                controller: _targetWeightTextController,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Please enter target weight";
                  }
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) {
                    return "Enter a valid weight";
                  }
                  if (parsed > 300) {
                    return "Please enter a realistic weight";
                  }
                  return null;
                },
                onChange: (val) {
                  if (val != null && val.isNotEmpty) {
                    controller.setTargetWeight("$val kg");
                  } else {
                    controller.setTargetWeight("");
                  }
                },
              ),

              SizedBox(height: 16),

              Obx(() {
                final range = _healthyRangeFromHeight();
                if (range == null) {
                  return SizedBox.shrink();
                }

                final currentWeight =
                    _parsePositiveDouble(controller.weightController.text) ?? 0;
                final goal = controller.selectedPG.value;
                final selectedTarget = _parseTargetWeight(
                  controller.selectedTargetWeight.value,
                );

                final suggestedKg = currentWeight > 0
                    ? _suggestedTargetKg(
                        currentWeight: currentWeight,
                        minKg: range.minKg,
                        maxKg: range.maxKg,
                      )
                    : null;

                final quickPicks = _quickPickWeights(
                  minKg: range.minKg,
                  maxKg: range.maxKg,
                  goal: goal,
                  currentWeight: currentWeight,
                );

                String adjustmentText;
                if (currentWeight <= 0) {
                  adjustmentText =
                      'Enter your current weight to see a personalized adjustment recommendation.';
                } else if (currentWeight < range.minKg) {
                  adjustmentText =
                      'Your current weight is below healthy range. Try selecting ${range.minKg.round()} kg or higher.';
                } else if (currentWeight > range.maxKg) {
                  adjustmentText =
                      'Your current weight is above healthy range. Try selecting ${range.maxKg.round()} kg or lower.';
                } else {
                  adjustmentText =
                      'You are already in the healthy range. Pick a target near your current weight for better consistency.';
                }

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xffFEF6FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xffFCE7F6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: Color(0xffDE2493),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          CustomText(
                            text: 'Healthy Target (BMI 18.5 to 25)',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xff851653),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      CustomText(
                        text:
                            'For your height ${_heightLabel(range.heightCm)} cm, recommended weight is ${range.minKg.toStringAsFixed(1)} to ${range.maxKg.toStringAsFixed(1)} kg.',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Color(0xff4D5761),
                      ),
                      if (suggestedKg != null) ...[
                        SizedBox(height: 6),
                        CustomText(
                          text: 'Suggested for your $goal goal: $suggestedKg kg',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Color(0xff851653),
                        ),
                      ],
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: quickPicks.map((weight) {
                          final isSelected =
                              selectedTarget != null &&
                              (selectedTarget - weight).abs() < 0.5;

                          return ChoiceChip(
                            label: Text('$weight kg'),
                            selected: isSelected,
                            onSelected: (_) => _applyTargetWeight(weight),
                            backgroundColor: Colors.white,
                            selectedColor: Color(0xff851653),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Color(0xff851653),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            side: BorderSide(color: Color(0xffE9D5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 8),
                      CustomText(
                        text: adjustmentText,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xff6C737F),
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: 16),

              /// ------------------ INFO BOX -------------------
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xffF9FAFB)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x08000000),
                      offset: Offset(0, 5),
                      blurRadius: 25,
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: Color(0x1B000000),
                      offset: Offset(0, 1.14),
                      blurRadius: 5.72,
                      spreadRadius: -2.67,
                    ),
                    BoxShadow(
                      color: Color(0x1F000000),
                      offset: Offset(0, 0.3),
                      blurRadius: 1.51,
                      spreadRadius: -1.33,
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: 8,
                  left: 12,
                  bottom: 12,
                  right: 13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 128,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(0xffFDF2FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xffFCE7F6)),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/star.png',
                              height: 12,
                              width: 11.91,
                              color: Color(0xffEF45B2),
                              colorBlendMode: BlendMode.srcIn,
                            ),
                            SizedBox(width: 4),
                            CustomText(
                              text: 'HEALTH BENEFIT',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xffEF45B2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Obx(() {
                      final currentWeight =
                          double.tryParse(controller.weightController.text) ??
                          0;
                      final healthyRange = _healthyRangeFromHeight();
                      final targetStr = controller.selectedTargetWeight.value;
                      final targetWeight =
                          double.tryParse(
                            targetStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                          ) ??
                          0;
                      final isTargetOutsideHealthyRange =
                          healthyRange != null &&
                          targetWeight > 0 &&
                          (targetWeight < healthyRange.minKg ||
                              targetWeight > healthyRange.maxKg);
                      final goal = controller.selectedPG.value;

                      String headlineText;
                      String detailText;

                      if (currentWeight > 0 && targetWeight > 0) {
                        final mismatch = validateGoalWeights(
                          goal: goal,
                          initialWeight: currentWeight,
                          targetWeight: targetWeight,
                          heightCm: healthyRange?.heightCm,
                        );

                        if (mismatch != null) {
                          headlineText = 'Target doesn\'t match your $goal goal';
                          detailText = mismatch;
                        } else {
                          switch (goal) {
                            case 'Weight Loss':
                            case 'Fat Loss':
                              final percent =
                                  ((currentWeight - targetWeight) /
                                          currentWeight *
                                          100)
                                      .toStringAsFixed(1);
                              headlineText =
                                  'You will lose $percent% of your weight';
                              detailText =
                                  'Scientific evidence shows that obesity-related conditions can be improved with 10% or higher weight loss';
                              break;
                            case 'Weight Gain':
                              final percent =
                                  ((targetWeight - currentWeight) /
                                          currentWeight *
                                          100)
                                      .toStringAsFixed(1);
                              headlineText =
                                  'You will gain $percent% more weight';
                              detailText =
                                  'Healthy weight gain can improve strength, immunity, and overall well-being';
                              break;
                            case 'Weight Maintenance':
                              headlineText =
                                  'Your target supports healthy weight maintenance';
                              detailText =
                                  'Staying consistent near your current weight helps build lasting habits';
                              break;
                            case 'Muscle Gain (Body Recomposition)':
                              headlineText =
                                  'Your target supports body recomposition';
                              detailText =
                                  'Building muscle while managing fat can improve strength and body composition, even if the scale barely moves';
                              break;
                            case 'Healthy Weight Management':
                              headlineText =
                                  'Your target is within a healthy range';
                              detailText =
                                  'Staying within a healthy BMI range supports long-term wellbeing';
                              break;
                            default:
                              headlineText = 'Target weight set';
                              detailText = '';
                          }
                        }
                      } else {
                        headlineText =
                            'Select a target weight to see health benefits';
                        detailText =
                            'We\'ll calculate health benefits based on your current weight and target';
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: headlineText,
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            color: Color(0xff851653),
                          ),
                          SizedBox(height: 10),
                          CustomText(
                            text: detailText,
                            fontWeight: FontWeight.w400,
                            fontSize: 13.5,
                            color: Color(0xff4D5761),
                            textAlign: TextAlign.center,
                          ),
                          if (isTargetOutsideHealthyRange) ...[
                            SizedBox(height: 8),
                            CustomText(
                              text:
                                  'Selected target is outside your healthy BMI range (${healthyRange.minKg.toStringAsFixed(1)} to ${healthyRange.maxKg.toStringAsFixed(1)} kg).',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xffB42318),
                            ),
                          ],
                        ],
                      );
                    }),
                    SizedBox(height: 11),
                    CustomText(
                      text:
                          'The research results are conditional and can differ from person to person. Please consult with some specialist or expert for more personal insights.',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xff9DA4AE),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              CustomButton(
                onTap: () {
                  if (formKey.currentState!.validate()) {
                    Get.to(() => ActivityLevelView());
                  }
                },
                text: 'Next',
                isOutline: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
