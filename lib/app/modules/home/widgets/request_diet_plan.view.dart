import 'package:docwellness/app/modules/home/views/main_request_diet_plan_view.dart';
import 'package:docwellness/app/modules/home/widgets/no_diet_widget.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _MembershipPlan {
  final String emoji;
  final String tabLabel;
  final String name;
  final double amount;
  final String tagline;
  final List<String> includes;
  final String bestFor;
  final String? badge;
  final String buttonText;

  const _MembershipPlan({
    required this.emoji,
    required this.tabLabel,
    required this.name,
    required this.amount,
    required this.tagline,
    required this.includes,
    required this.bestFor,
    this.badge,
    required this.buttonText,
  });
}

const _membershipPlans = [
  _MembershipPlan(
    emoji: '🥈',
    tabLabel: 'Silver',
    name: 'Silver Membership',
    amount: 1500,
    tagline: 'Simple wellness. Better daily habits.',
    includes: [
      '🥗 One personalized monthly diet plan',
      '📅 Weekly plan repeats monthly',
      '▶️ Curated YouTube workout videos',
      '📈 Daily health tracking',
      '⚖️ Weight and measurement logging',
      '📊 Progress reports and insights',
      '🎯 Monthly wellness goals',
    ],
    bestFor: 'Healthy lifestyle beginners.',
    buttonText: 'Start Silver',
  ),
  _MembershipPlan(
    emoji: '🥇',
    tabLabel: 'Golden',
    name: 'Golden Membership',
    amount: 2500,
    tagline: 'Smarter plans. Better monthly results.',
    includes: [
      '🥗 Two personalized diet plans',
      '📅 Week 1 meal plan',
      '📅 Week 2 meal plan',
      '🔄 Weeks 3–4 updated plan',
      '📈 Based on Week 2 progress',
      '🎥 Premium workout videos',
      '▶️ YouTube workout library',
      '📈 Daily health tracking',
      '⚖️ Weight and measurement logging',
      '📊 Detailed progress reports',
      '🎯 Personalized wellness goals',
    ],
    bestFor: 'Faster health improvements.',
    badge: 'Most Popular',
    buttonText: 'Choose Golden',
  ),
  _MembershipPlan(
    emoji: '💎',
    tabLabel: 'Platinum',
    name: 'Platinum Membership',
    amount: 5500,
    tagline: 'Complete wellness with expert guidance.',
    includes: [
      '🥗 Weekly personalized diet plans',
      '🔄 Weekly diet plan updates',
      '📈 Based on weekly progress',
      '🎥 Premium workout video library',
      '💬 Personal diet consultation',
      '❤️ Motivation counselling sessions',
      '📞 Priority expert support',
      '📈 Daily health tracking',
      '⚖️ Weight and measurement logging',
      '📊 Comprehensive progress reports',
      '🎯 Continuous wellness guidance',
    ],
    bestFor: 'Complete personalized wellness support.',
    badge: 'Premium Plan',
    buttonText: 'Go Platinum',
  ),
];

class RequestDietPlanScreen extends StatefulWidget {
  const RequestDietPlanScreen({super.key});

  @override
  State<RequestDietPlanScreen> createState() => _RequestDietPlanScreenState();
}

class _RequestDietPlanScreenState extends State<RequestDietPlanScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Preserve whichever plan was last selected (e.g. when returning here
    // after "Update Plan Request") instead of always resetting to Silver.
    if (Get.isRegistered<HomeController>()) {
      final lastSelected = Get.find<HomeController>().selectedPlanName.value;
      final savedIndex = _membershipPlans.indexWhere(
        (p) => p.name == lastSelected,
      );
      if (savedIndex != -1) {
        _selectedIndex = savedIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _membershipPlans[_selectedIndex];

    return Scaffold(
      extendBodyBehindAppBar: false,

      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: const Color(0xffFDF2FA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
          onPressed: () {
            Get.off(() => MainRequestDietPlanView());
          },
        ),
        titleSpacing: 0,
        title: CustomText(
          text: 'Select Plan',
          fontWeight: FontWeight.w400,
          fontSize: 18,
          color: Color(0xff1F2A37),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            children: [
              const SizedBox(height: 24),

              _buildTabBar(),

              const SizedBox(height: 20),

              _buildPlanCard(plan),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: List.generate(_membershipPlans.length, (index) {
        final isSelected = index == _selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                CustomText(
                  text: _membershipPlans[index].tabLabel,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xff851653)
                      : const Color(0xff9DA4AE),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 2,
                  color: isSelected
                      ? const Color(0xff851653)
                      : const Color(0xffE9D5E1),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPlanCard(_MembershipPlan plan) {
    final controller = Get.find<HomeController>();
    final amountLabel = plan.amount.toInt().toString();

    return Container(
      key: ValueKey(plan.name),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xffF9FAFB)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xffFDF2FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffFCE7F6)),
              ),
              child: CustomText(
                text: plan.badge!,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xffEF45B2),
              ),
            ),
            const SizedBox(height: 12),
          ],

          CustomText(
            text: '${plan.emoji} ${plan.name}',
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: const Color(0xff851653),
          ),
          const SizedBox(height: 4),
          CustomText(
            text: '₹${_thousands(plan.amount)}/month',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xff020617),
          ),
          const SizedBox(height: 8),
          CustomText(
            text: plan.tagline,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xff4D5761),
          ),

          const SizedBox(height: 20),
          CustomText(
            text: 'Includes',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xff851653),
          ),
          const SizedBox(height: 8),
          for (final item in plan.includes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: CustomText(
                text: item,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xff384250),
              ),
            ),

          const SizedBox(height: 16),
          CustomText(
            text: 'Best For',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xff851653),
          ),
          const SizedBox(height: 6),
          CustomText(
            text: plan.bestFor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xff384250),
          ),

          const SizedBox(height: 20),
          CustomButton(
            buttonColor: Color(0xff851653),
            onTap: () async {
              await controller.selectPlan(name: plan.name, amount: plan.amount);
              Get.off(() => const NoDietWidget());
            },
            text: plan.buttonText,
            isOutline: false,
            fontSize: 14,
          ),

          const SizedBox(height: 10),

          CustomText(
            text:
                'By proceeding, you agree to our terms and authorize a ₹$amountLabel for one month charge.',

            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xff9DA4AE),
            height: 1.5,

            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _thousands(double amount) {
    final intAmount = amount.toInt();
    final digits = intAmount.toString();
    if (digits.length <= 3) return digits;
    final lastThree = digits.substring(digits.length - 3);
    final rest = digits.substring(0, digits.length - 3);
    final withCommas = rest.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (m) => ',',
    );
    return '$withCommas,$lastThree';
  }
}
