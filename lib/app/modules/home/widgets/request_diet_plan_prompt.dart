import 'package:docwellness/app/modules/home/views/main_request_diet_plan_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shown on the Diet & Exercise tab instead of [NoDietWidget] when the
/// patient hasn't submitted a diet plan request yet at all - NoDietWidget's
/// "I am currently working on your Diet & Nutrition plan" copy is only true
/// once a request actually exists (see HomeController.hasRequest, already
/// used on Home to decide between a "Request diet plan" CTA and the
/// Active-plan actions). Reusing that same copy/flow here instead of
/// inventing a second one - Home's CustomButton with this exact text
/// already navigates to MainRequestDietPlanView.
class RequestDietPlanPrompt extends StatelessWidget {
  /// See NoDietWidget.embedded's doc comment - same contract: true inside
  /// DietAndExerciseScreen's combined Scaffold (which owns the bottom
  /// action slot via RequestDietPlanAction below), false for a standalone
  /// route with its own Scaffold/AppBar/CTA.
  final bool embedded;

  const RequestDietPlanPrompt({super.key, this.embedded = false});

  Widget _body() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 43),
          Image.asset(
            'assets/icons/60d178b5113c2afe80c762a7ff3554a8f1a3f8c3.gif',
          ),
          const SizedBox(height: 40),
          const CustomText(
            text: "Let's get you started",
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xff851653),
          ),
          const SizedBox(height: 13),
          const CustomText(
            text:
                "You haven't requested a diet plan yet. Tell us about your goals and get a plan tailored just for you.",
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xff4D5761),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (!embedded) ...[
            const RequestDietPlanButton(),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (embedded) return _body();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const CustomText(
          text: "Diet Plan",
          color: Color(0xff1F2A37),
          fontWeight: FontWeight.w400,
          fontSize: 20,
        ),
      ),
      body: _body(),
    );
  }
}

/// The single "Request diet plan" CTA - same text/style as the button Home
/// shows for a patient with no request yet, so the two entry points read as
/// one consistent prompt rather than two different flows.
class RequestDietPlanButton extends StatelessWidget {
  const RequestDietPlanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomButton(
        onTap: () => Get.to(() => const MainRequestDietPlanView()),
        text: 'Request diet plan',
        fontSize: 14,
        isOutline: false,
      ),
    );
  }
}

/// The Diet & Exercise tab's bottom action slot for this state - mirrors
/// DietInfoActions' SafeArea/padding shell so swapping between the two
/// waiting states never shifts layout, but carries only the one CTA that
/// actually applies before any request exists (no "Contact us" - there's no
/// dietician relationship yet to contact about).
class RequestDietPlanAction extends StatelessWidget {
  const RequestDietPlanAction({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: const RequestDietPlanButton(),
      ),
    );
  }
}
