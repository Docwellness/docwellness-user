import 'package:docwellness/app/modules/home/views/main_request_diet_plan_view.dart';
import 'package:docwellness/app/modules/home/views/order_summary_view.dart';
import 'package:docwellness/app/modules/home/views/view_first_consultation_view.dart';
import 'package:docwellness/app/modules/home/widgets/about_me_section.dart';
import 'package:docwellness/app/modules/home/widgets/client_journey_section.dart';
import 'package:docwellness/app/modules/goal_journey/widgets/journey_card.dart';
import 'package:docwellness/app/modules/home/widgets/home_diet_countdown_card.dart';
import 'package:docwellness/app/modules/home/widgets/payment_status_sheet.dart';
import 'package:docwellness/app/modules/home/widgets/progress_card.dart';
import 'package:docwellness/app/modules/home/widgets/quotes_section.dart';
import 'package:docwellness/app/modules/home/widgets/request_diet_plan.view.dart';
import 'package:docwellness/app/modules/home/widgets/videos_section.dart';
import 'package:docwellness/app/modules/home/widgets/water_intake_container.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/shared/widgets/app_loader.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});
  final HomeController controller = Get.find<HomeController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx(() {
        final count = controller.chatUnreadCount.value;
        return SizedBox(
          height: 77,
          width: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                onPressed: () async {
                  controller.chatUnreadCount.value = 0;
                  await Get.toNamed(Routes.CHAT);
                  controller.fetchChatUnreadCount();
                },
                backgroundColor: const Color(0xFF7B1A56),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Image.asset(
                  'assets/icons/chat.png',
                  width: 30,
                  height: 30,
                  color: Colors.white,
                  fit: BoxFit.cover,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xffDE2493),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),

      extendBodyBehindAppBar: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xffFDF2FA),
        title: Obx(() {
          final name = controller.userName.value;
          final greeting = controller.getGreeting();
          return CustomText(
            text: name.isEmpty ? greeting : '$greeting $name',
            fontWeight: FontWeight.w400,
            fontSize: 21,
            color: Color(0xff530630),
          );
        }),
        actions: [
          Obx(() {
            final count = controller.notificationUnreadCount.value;
            return GestureDetector(
              onTap: () async {
                await Get.toNamed(Routes.NOTIFICATIONS);
                controller.fetchNotificationCount();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications, color: Color(0xff4D5761)),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xffDE2493),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xff851653),
        backgroundColor: Colors.white,
        strokeWidth: 3,
        displacement: 40,
        onRefresh: () async {
          await controller.refreshAllData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // JourneyCard applies its own 16px horizontal margin
              // internally (see journey_card.dart), so only top/bottom
              // spacing goes here - wrapping it in a horizontally-padded
              // Padding too would double up to 32px.
              const SizedBox(height: 20),
              const JourneyCard(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xffFEF6FB),
                    border: cardBorder,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: cardShadow,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          left: 21,
                        ),
                        child: Obx(
                          () => GestureDetector(
                            onTap: controller.canGoBack
                                ? () => controller.changeDate(-1)
                                : null,
                            child: Opacity(
                              opacity: controller.canGoBack ? 1.0 : 0.3,
                              child: Image.asset(
                                'assets/icons/home_left_arrow.png',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                      Obx(
                        () => CustomText(
                          text: controller.selectedDateLabel,
                          fontWeight: FontWeight.w400,
                          fontSize: 20,
                          color: Color(0xff530630),
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          right: 21,
                        ),
                        child: Obx(
                          () => GestureDetector(
                            onTap: controller.canGoForward
                                ? () => controller.changeDate(1)
                                : null,
                            child: Opacity(
                              opacity: controller.canGoForward ? 1.0 : 0.3,
                              child: Image.asset(
                                'assets/icons/home_right_arrow.png',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  // Whenever the diet is enabled, the water card would show
                  // (see the old standalone condition below) - merge it
                  // into one card with calories/macros, split by a dashed
                  // divider, instead of two separately-bordered cards.
                  // While the diet isn't enabled there's nothing loggable
                  // yet (no water card either), so ProgressCard stays
                  // standalone showing its own BMI-only empty state.
                  final merged = controller.dietEnabled.value;
                  final progressBody = ProgressCard(
                    standalone: !merged,
                    hasData:
                        controller.hasProgressData.value &&
                        controller.dietEnabled.value,
                    intake: controller.progressIntake.value,
                    remaining: controller.progressRemaining.value,
                    exercise: controller.progressExercise.value,
                    totalPlanned: controller.progressTotalPlanned.value,
                    carbsConsumed: controller.carbsConsumed.value,
                    carbsPlanned: controller.carbsPlanned.value,
                    proteinConsumed: controller.proteinConsumed.value,
                    proteinPlanned: controller.proteinPlanned.value,
                    fiberConsumed: controller.fiberConsumed.value,
                    fiberPlanned: controller.fiberPlanned.value,
                    fatConsumed: controller.fatConsumed.value,
                    fatPlanned: controller.fatPlanned.value,
                    bmiValue: controller.bmiValue.value,
                    bmiIndex: controller.bmiIndex.value,
                    targetWeight: controller.targetedWeight.value,
                    activityLevel: controller.activityLevel.value,
                    healthConcerns: controller.illness,
                  );

                  if (!merged) return progressBody;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: cardBorder,
                      color: const Color(0xffFEF6FB),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: cardShadow,
                    ),
                    child: Column(
                      children: [
                        progressBody,
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: _DashedDivider(color: Color(0xffEF45B2)),
                        ),
                        const WaterIntakeContainer(),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // The countdown card only shows while the diet isn't enabled
              // yet (mutually exclusive with the merged card's water
              // section above, which only appears once it is).
              Obx(() {
                final startsAt = controller.dietStartsAt.value;
                if (controller.dietEnabled.value || startsAt == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: HomeDietCountdownCard(startDate: startsAt),
                );
              }),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() => _buildActionButton(context)),
              ),
              const SizedBox(height: 16),
              VideosSection(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuotesSection(),
              ),
              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomText(
                  text: 'About me',
                  fontWeight: FontWeight.w400,
                  fontSize: 17,
                  color: Color(0xff530630),
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => AboutMeSection(doctor: controller.doctorProfile.value),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClientJourneySection(titleReruired: true),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the action button based on current request status
  Widget _buildActionButton(BuildContext context) {
    if (controller.isLoadingRequestStatus.value) {
      return const AppLoader();
    }

    final status = controller.requestStatus.value;
    final hasRequest = controller.hasRequest.value;

    // No request yet - show "Request Diet Plan"
    if (!hasRequest || status.isEmpty) {
      return CustomButton(
        onTap: () {
          Get.to(() => MainRequestDietPlanView());
        },
        text: "Request diet plan",
        fontSize: 14,
        isOutline: false,
      );
    }

    // Status: Unpaid - dietician hasn't sent a payment request yet. Once
    // they've filled in a first consultation, let the patient review it and
    // give consent; before that, there's nothing to view yet.
    if (status == 'Unpaid') {
      // Consent already submitted - button's job is done, diet plan is next.
      if (controller.hasFirstConsultation.value &&
          controller.firstConsultationConsented.value) {
        return _infoBanner(
          icon: Icons.hourglass_top,
          text: 'Your Diet Plan is getting prepared, please wait.',
        );
      }

      // First consultation exists but not yet consented.
      if (controller.hasFirstConsultation.value) {
        return CustomButton(
          onTap: () {
            Get.to(() => const ViewFirstConsultationView());
          },
          text: "View First Consultation",
          fontSize: 14,
          isOutline: false,
        );
      }

      // No first consultation yet - Order Summary lets the patient review
      // (and, via its own "Update Plan Request" button, edit) what they
      // submitted. Once a consultation exists there's nothing left to
      // review/edit here, so the button is pre-consultation only.
      return Column(
        children: [
          _infoBanner(
            icon: Icons.check_circle,
            text:
                'Your request has been received. Dr. Tejasvini will soon organise a personal consultation with you.',
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CustomButton(
              onTap: () {
                Get.to(() => const OrderSummaryView());
              },
              text: "Order Summary",
              fontSize: 14,
              isOutline: true,
            ),
          ),
        ],
      );
    }

    // Status: PaymentRequested - show "Send Payment Details"
    if (status == 'PaymentRequested') {
      return CustomButton(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            useSafeArea: true,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return DraggableScrollableSheet(
                initialChildSize: 1,
                maxChildSize: 1,
                minChildSize: 0.5,
                expand: false,
                builder: (context, scrollController) {
                  return PaymentStatusSheet(scrollController: scrollController);
                },
              );
            },
          );
        },
        text: "Send Payment Details",
        fontSize: 14,
        isOutline: false,
      );
    }

    // Status: PaymentSubmitted - this is a renewal payment awaiting the
    // dietician's review, not a fresh signup: the patient's diet plan from
    // their prior (still-unexpired-in-the-database) cycle stays active and
    // loggable the whole time (see getActiveDietPlanForPatient - it keys
    // off DietPlan.status alone, not this request's payment status), so
    // don't lock them out of logging meals while the new payment is
    // reviewed. Only this status gets this treatment - PaymentRequested and
    // Unpaid mean there's genuinely nothing to log against yet.
    if (status == 'PaymentSubmitted') {
      return _logMealAndExerciseButtons();
    }

    // Status: Paid or PartiallyPaid - the plan is activated either way (see
    // backend activateDietPlan); PartiallyPaid just still owes a balance,
    // which gets its own small notice above the usual Paid experience.
    if (status == 'Paid' || status == 'PartiallyPaid') {
      return Column(
        children: [
          if (status == 'PartiallyPaid') ...[
            _infoBanner(
              icon: Icons.info_outline,
              text:
                  'You have a pending balance of ₹${controller.latestAmountPending.value.toStringAsFixed(0)}. '
                  'Please complete your payment.',
            ),
            SizedBox(height: 12),
          ],
          _buildSubscriptionBanner(),
          SizedBox(height: 12),
          if (!controller.isSubscriptionExpired) _logMealAndExerciseButtons(),
          if (status == 'PartiallyPaid') ...[
            SizedBox(height: 12),
            CustomButton(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  useSafeArea: true,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return DraggableScrollableSheet(
                      initialChildSize: 1,
                      maxChildSize: 1,
                      minChildSize: 0.5,
                      expand: false,
                      builder: (context, scrollController) {
                        return PaymentStatusSheet(
                          scrollController: scrollController,
                          isPendingPayment: true,
                        );
                      },
                    );
                  },
                );
              },
              text: "Pay Remaining Balance",
              fontSize: 14,
              isOutline: true,
            ),
          ],
          if (controller.isSubscriptionExpired)
            CustomButton(
              onTap: () async {
                // Skip the full intake form - consultation/personal data
                // already exists, so jump straight to picking a plan (see
                // HomeController.startRenewal, which resets the existing
                // request's payment/status fields for the new cycle).
                await controller.startRenewal();
                Get.to(() => const RequestDietPlanScreen());
              },
              text: "Renew Subscription",
              fontSize: 14,
              isOutline: false,
            ),
        ],
      );
    }

    // Default fallback
    return CustomButton(
      onTap: () {
        Get.to(() => MainRequestDietPlanView());
      },
      text: "Request diet plan",
      fontSize: 14,
      isOutline: false,
    );
  }

  Widget _infoBanner({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff851653), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              text: text,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xff4D5761),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logMealAndExerciseButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            enabled: controller.dietEnabled.value,
            onTap: () => controller.changeTab(2), // Diet & Exercise tab
            text: "Log Meal",
            fontSize: 14,
            isOutline: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            enabled: controller.dietEnabled.value,
            onTap: () => Get.toNamed(Routes.EXERCISE),
            text: "Log Exercise",
            fontSize: 14,
            isOutline: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBanner() {
    final expiresAt = controller.subscriptionExpiresAt.value;
    if (expiresAt == null) return SizedBox.shrink();
    // See HomeController.hasPaidSubscriptionCycle - a stale expiry date
    // can outlive the cycle it belonged to (e.g. once a renewal has
    // started and requestStatus is back to 'Unpaid'), which isn't the
    // patient's *current* subscription state regardless of the date math.
    if (!controller.hasPaidSubscriptionCycle) return SizedBox.shrink();
    // The subscription is considered to start when the diet plan itself
    // starts, not at the moment of payment - while HomeDietCountdownCard's
    // "Diet plan starts in X" timer is still showing (dietEnabled false),
    // this banner has nothing true to say yet either, so it stays hidden
    // until the same dietEnabled flip that reveals the rest of Home's
    // plan-active UI (see the countdown card above and WaterIntakeContainer).
    if (!controller.dietEnabled.value) return SizedBox.shrink();

    final isExpired = controller.isSubscriptionExpired;
    final daysLeft = controller.daysRemaining;
    final expiryDate = DateFormat('dd MMM yyyy').format(expiresAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xffFEF2F2) : const Color(0xffF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? const Color(0xffFECACA) : const Color(0xffBBF7D0),
        ),
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.error_outline : Icons.check_circle_outline,
            color: isExpired
                ? const Color(0xffDC2626)
                : const Color(0xff16A34A),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: isExpired
                      ? 'Subscription Expired'
                      : 'Subscription Active',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isExpired
                      ? const Color(0xffDC2626)
                      : const Color(0xff16A34A),
                ),
                const SizedBox(height: 2),
                CustomText(
                  text: isExpired
                      ? 'Expired on $expiryDate. Please renew to continue.'
                      : '$daysLeft days remaining \u2022 Expires $expiryDate',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: isExpired
                      ? const Color(0xff991B1B)
                      : const Color(0xff166534),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal dashed line - separates the calorie/macro section from the
/// water intake section inside the merged Home progress card. Flutter has
/// no built-in dashed line, same reasoning as diet_view.dart's
/// _DashedRoundedRectPainter for a dashed border.
class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  static const double _dashWidth = 6;
  static const double _dashGap = 4;
  static const double _thickness = 1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _thickness,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color: color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _DashedDivider._thickness;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + _DashedDivider._dashWidth, 0),
        paint,
      );
      x += _DashedDivider._dashWidth + _DashedDivider._dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
