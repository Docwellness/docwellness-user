import 'package:docwellness/app/modules/auth/widgets/bmi_container.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/views/main_request_diet_plan_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Read-only review of what was submitted: Step 1 (personal information +
/// BMI) and Step 2 (selected membership plan). Reachable from the "Order
/// Summary" home button while a request is Unpaid.
class OrderSummaryView extends StatefulWidget {
  const OrderSummaryView({super.key});

  @override
  State<OrderSummaryView> createState() => _OrderSummaryViewState();
}

class _OrderSummaryViewState extends State<OrderSummaryView> {
  final HomeController controller = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    // Fetch straight from the diet plan request itself (not the mutable
    // patient profile) - this is the actual submitted record, includes the
    // start date, and reflects the selected membership plan.
    // Deferred past the current frame since this mutates Rx fields before
    // its first await, and Home stays mounted underneath this screen with
    // its own Obx watching the same HomeController fields (see the same
    // fix/comment in MainRequestDietPlanView.initState()).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchRequestDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: const CustomText(
          text: 'Order Summary',
          fontWeight: FontWeight.w400,
          fontSize: 18,
          color: Color(0xff1F2A37),
        ),
      ),
      body: Obx(
        () => controller.isRequestDietPlanLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ---------- STEP 1: PERSONAL INFORMATION ----------
          Center(
            child: CustomText(
              text: 'Step 1 · Personal Information',
              fontWeight: FontWeight.w500,
              fontSize: 17,
              color: Color(0xff851653),
            ),
          ),
          const SizedBox(height: 16),

          _summaryCard([
            _ReadOnlyRow(
              label: 'Start Date for Diet',
              value: controller.requestUserStartDate.text,
            ),
            _ReadOnlyRow(
              label: 'Full name',
              value: controller.requestUserName.text,
            ),
            _ReadOnlyRow(
              label: 'Date of Birth',
              value: controller.requestUserDob.text,
            ),
            _ReadOnlyRow(
              label: 'Gender',
              value: controller.selectedGender.value,
            ),
            _ReadOnlyRow(
              label: 'Initial Weight',
              value: '${controller.requestUserWeight.text} Kg',
            ),
            _ReadOnlyRow(
              label: 'Height',
              value: '${controller.requestUserHeight.text} CM',
              isLast: true,
            ),
          ]),

          const SizedBox(height: 16),
          Obx(
            () => BmiContainer(
              index: controller.bmiIndex.value,
              value: controller.bmiValue.value,
              targetedWeight: controller.targetedWeight.value,
              activityLevel: null,
              healthConcerentList: controller.illness.toList(),
              activityLevelText: controller.activityLevel.value,
            ),
          ),

          const SizedBox(height: 28),

          // ---------- STEP 2: SELECTED PLAN ----------
          Center(
            child: CustomText(
              text: 'Step 2 · Selected Plan',
              fontWeight: FontWeight.w500,
              fontSize: 17,
              color: Color(0xff851653),
            ),
          ),
          const SizedBox(height: 16),

          Obx(
            () => _summaryCard([
              _ReadOnlyRow(
                label: 'Membership',
                value: controller.selectedPlanName.value,
              ),
              _ReadOnlyRow(
                label: 'Amount',
                value: '₹${controller.selectedPlanAmount.value.toInt()}/month',
                isLast: true,
              ),
            ]),
          ),

          const SizedBox(height: 28),

          // ---------- UPDATE PLAN REQUEST ----------
          // Only while the dietician hasn't sent a payment request yet -
          // same condition that currently gates the home screen's
          // "Awaiting Payment Request" state.
          Obx(() {
            if (controller.requestStatus.value != 'Unpaid') {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: CustomButton(
                onTap: () {
                  Get.to(() => MainRequestDietPlanView());
                },
                text: 'Update Plan Request',
                isOutline: true,
                fontSize: 14,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffF9FAFB)),
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
      child: Column(children: rows),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _ReadOnlyRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xffF3F4F6)),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: label,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xff6C737F),
          ),
          Flexible(
            child: CustomText(
              text: value.isEmpty ? '--' : value,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xff384250),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
