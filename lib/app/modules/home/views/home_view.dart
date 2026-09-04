import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/home/views/main_request_diet_plan_view.dart';
import 'package:docwellness/app/modules/home/views/order_summary_view.dart';
import 'package:docwellness/app/modules/home/views/view_first_consultation_view.dart';
import 'package:docwellness/app/modules/home/widgets/about_me_section.dart';
import 'package:docwellness/app/modules/home/widgets/active_plan_actions.dart';
import 'package:docwellness/app/modules/home/widgets/client_journey_section.dart';
import 'package:docwellness/app/modules/goal_journey/widgets/journey_card.dart';
import 'package:docwellness/app/modules/home/widgets/home_diet_countdown_card.dart';
import 'package:docwellness/app/modules/home/widgets/payment_status_sheet.dart';
import 'package:docwellness/app/modules/home/widgets/progress_card.dart';
import 'package:docwellness/app/modules/home/widgets/quotes_section.dart';
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
              // Button+badge anchored together to the box's own
              // bottom-right corner - left unpositioned, a Stack child
              // defaults to the top-left instead, so the ~56dp button sat
              // inside this 80x77 box (sized to leave room for the badge to
              // overflow past its edges) noticeably left of and above
              // where it should land: Scaffold pins this whole box's
              // bottom-right corner to the standard FAB margin, which only
              // lines the button's own edge up with the home screen cards'
              // matching 16px right padding once the button itself - not
              // just its box - is flush with that corner. The badge is
              // nested inside this same Positioned (relative to the
              // button's own bounds, not the box's) so it stays pinned to
              // the button's actual top-right corner wherever the button
              // itself ends up, instead of floating at a fixed spot in the
              // box that only lined up by coincidence with the button's
              // old top-left position.
              Positioned(
                right: 0,
                bottom: 0,
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
                        right: -4,
                        top: -4,
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
        // A primary bottom-nav destination - never a back arrow, even when
        // it was reached via a push that leaves a Navigator entry behind it
        // (see diet_and_exercise_screen's same fix).
        automaticallyImplyLeading: false,
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
              const SizedBox(height: 8),
              // The countdown card only shows while the diet isn't enabled
              // yet (mutually exclusive with the merged card's water
              // section above, which only appears once it is).
              Obx(() {
                final startsAt = controller.dietStartsAt.value;
                if (controller.dietEnabled.value || startsAt == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: HomeDietCountdownCard(startDate: startsAt),
                );
              }),
              const SizedBox(height: 8),
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
      // A renewal kicked off from the pre-expiry "Request diet plan" button
      // flips the request back to Unpaid while the previous cycle's diet
      // plan stays Active and loggable (getActiveDietPlanForPatient keys off
      // DietPlan.status alone). Keep Log Meal / Log Exercise available
      // through that window instead of dropping straight to the
      // "request received" state - hasDietPlan is only ever true here for a
      // renewing patient, never a brand-new signup.
      if (controller.hasDietPlan.value &&
          controller.dietEnabled.value &&
          !controller.isSubscriptionExpired) {
        return Column(
          children: [
            ActivePlanActions(
              dietEnabled: controller.dietEnabled.value,
              showRequestDietPlan: false,
              onLogMeal: () => _openDietTab(0),
              onLogExercise: () => _openDietTab(1),
              onRequestDietPlan: _startDietPlanRenewal,
            ),
            const SizedBox(height: 12),
            _infoBanner(
              icon: Icons.hourglass_top,
              text:
                  'Your next diet plan request is in progress. Keep logging '
                  'against your current plan until the new one starts.',
            ),
            const SizedBox(height: 12),
            CustomButton(
              onTap: () => Get.to(() => const OrderSummaryView()),
              text: "Order Summary",
              fontSize: 14,
              isOutline: true,
            ),
          ],
        );
      }

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

    // Status: PaymentSubmitted - could be either a renewal payment awaiting
    // the dietician's review, or a fresh signup's first payment proof.
    // For a renewal, the patient's diet plan from their prior
    // (still-unexpired-in-the-database) cycle stays active and loggable the
    // whole time (see getActiveDietPlanForPatient - it keys off
    // DietPlan.status alone, not this request's payment status), so keep the
    // log buttons visible. For a fresh signup there is no diet plan yet -
    // the plan only exists once the dietician approves the payment and
    // activates it - so showing (disabled) Log Meal / Log Exercise buttons
    // here is misleading. Gate on an actual active plan existing.
    if (status == 'PaymentSubmitted') {
      if (controller.hasDietPlan.value) {
        return ActivePlanActions(
          dietEnabled: controller.dietEnabled.value,
          showRequestDietPlan: false,
          onLogMeal: () => _openDietTab(0),
          onLogExercise: () => _openDietTab(1),
          onRequestDietPlan: _startDietPlanRenewal,
        );
      }
      return _infoBanner(
        icon: Icons.hourglass_top,
        text:
            'Your payment details have been submitted. Your dietician will '
            'review them and activate your diet plan shortly.',
      );
    }

    // Status: Paid or PartiallyPaid - the plan is activated either way (see
    // backend activateDietPlan); PartiallyPaid just still owes a balance,
    // which gets its own small notice above the usual Paid experience.
    if (status == 'Paid' || status == 'PartiallyPaid') {
      final isExpired = controller.isSubscriptionExpired;
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
          // While the cycle is still active there's no "Subscription
          // Active" banner - the Goal Journey card already shows
          // completed/remaining days. The log buttons stay; a
          // "Request diet plan" button joins them (showRequestDietPlan)
          // once we're within kRenewalWindowDays of expiry.
          if (!isExpired)
            ActivePlanActions(
              dietEnabled: controller.dietEnabled.value,
              showRequestDietPlan: controller.isRenewalDue,
              onLogMeal: () => _openDietTab(0),
              onLogExercise: () => _openDietTab(1),
              onRequestDietPlan: _startDietPlanRenewal,
            ),
          if (isExpired) ...[
            _buildExpiredSubscriptionBanner(),
            SizedBox(height: 12),
            CustomButton(
              onTap: _startDietPlanRenewal,
              text: "Request diet plan",
              fontSize: 14,
              isOutline: false,
            ),
          ],
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

  /// Switches to the Diet & Exercise tab and asks that screen's pill
  /// switcher to land on Diet Plan ([focusMode] 0) or Exercises
  /// ([focusMode] 1). This deliberately switches tabs rather than pushing a
  /// route: DietAndExerciseScreen's State is kept alive across tab switches
  /// (see bottom_navi_bar.dart's IndexedStack), so without focusModeRequest
  /// it would keep whichever pill was last selected, and pushing
  /// ExerciseView as its own route would lose the bottom nav bar entirely.
  void _openDietTab(int focusMode) {
    controller.changeTab(2); // Diet & Exercise tab
    if (Get.isRegistered<DietController>()) {
      Get.find<DietController>().focusModeRequest.value = focusMode;
    }
  }

  /// Opens the renewal request through the exact same flow as a first-time
  /// request: edit personal data (MainRequestDietPlanView) -> pick a plan
  /// (RequestDietPlanScreen) -> "No diet assigned".
  ///
  /// No backend call here - tapping the button just opens the form. Nothing
  /// is created until the patient submits "Select Plan": sendRequestDietPlan
  /// POSTs to createDietPlanRequest, which detects the active paid cycle,
  /// resets it for the new cycle (no duplicate row on the dietician's list)
  /// and notifies the dietician. The current cycle's plan stays Active and
  /// loggable until the new one is activated.
  void _startDietPlanRenewal() {
    Get.to(() => const MainRequestDietPlanView());
  }

  /// Shown only once the paid cycle has actually lapsed. While the cycle is
  /// still active there's no banner here - the Goal Journey card already
  /// shows completed/remaining days, and the "Request diet plan" button
  /// (see ActivePlanActions) appears on its own once the cycle is within
  /// kRenewalWindowDays of expiry.
  Widget _buildExpiredSubscriptionBanner() {
    final expiresAt = controller.subscriptionExpiresAt.value;
    if (expiresAt == null) return const SizedBox.shrink();
    final expiryDate = DateFormat('dd MMM yyyy').format(expiresAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffFECACA)),
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xffDC2626),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  text: 'Subscription Expired',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xffDC2626),
                ),
                const SizedBox(height: 2),
                CustomText(
                  text:
                      'Expired on $expiryDate. Request your next diet plan to continue.',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: const Color(0xff991B1B),
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
