import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_datepicker.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentStatusSheet extends StatefulWidget {
  final ScrollController scrollController;

  /// When true (opened from profile), the amount owed is the previously
  /// recorded pending balance instead of the subscription total, and the
  /// coupon section is hidden (a coupon only applies to the original
  /// subscription purchase).
  final bool isPendingPayment;
  const PaymentStatusSheet({
    super.key,
    required this.scrollController,
    this.isPendingPayment = false,
  });

  @override
  State<PaymentStatusSheet> createState() => _PaymentStatusSheetState();
}

class _PaymentStatusSheetState extends State<PaymentStatusSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final HomeController controller = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    // One-time default (paid in full) - deliberately not in build(), which
    // DraggableScrollableSheet re-invokes on every drag frame and would
    // otherwise stomp whatever the patient has already typed.
    controller.initPaymentForm(isPendingPayment: widget.isPendingPayment);
  }

  double get _amountOwed => widget.isPendingPayment
      ? controller.latestAmountPending.value
      : controller.finalAmount.value;

  Widget _buildReadOnlyRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: 14,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          color: Color(0xff4D5761),
        ),
        CustomText(
          text: value,
          fontSize: isBold ? 16 : 14,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: valueColor ?? Color(0xff1F2A37),
        ),
      ],
    );
  }

  String _formatAmount(double amount) =>
      amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: formKey,
        child: ListView(
          controller: widget.scrollController,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                decoration: BoxDecoration(
                  color: Color(0xff79747E),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                  ),
                  SizedBox(width: 14),
                  CustomText(
                    text: 'Payment Status',
                    fontWeight: FontWeight.w400,
                    fontSize: 19,
                    color: Color(0xff1F2A37),
                  ),
                ],
              ),
            ),
            Divider(color: Color(0xff9DA4AE)),
            SizedBox(height: 20),

            // ── 1. Payment proof image ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => GestureDetector(
                  onTap: () => controller.pickPaymentImage(),
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xffFEF6FB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xffFCE7F6)),
                    ),
                    child: Center(
                      // Image.memory, not Image.file(File(path)) - XFile.path
                      // is only a blob: URL on Flutter Web, not a real
                      // filesystem path, so dart:io File access silently
                      // failed there and the preview never rendered (same
                      // fix as chat_view.dart's photo preview).
                      child: controller.pickedPaymentImageBytes.value == null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/camera.png',
                                  height: 44,
                                ),
                                SizedBox(height: 10),
                                CustomText(
                                  text: 'Upload payment proof',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff851653),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                controller.pickedPaymentImageBytes.value!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 18),

            // ── 2. Subscription/pending amount summary ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xffFAFAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xffE5E7EB)),
                ),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isPendingPayment)
                        _buildReadOnlyRow(
                          'Pending Amount',
                          '₹${_formatAmount(controller.latestAmountPending.value)}',
                          isBold: true,
                          valueColor: Color(0xff851653),
                        )
                      else ...[
                        _buildReadOnlyRow(
                          'Subscription Amount',
                          '₹${controller.selectedPlanAmount.value.toInt()}',
                        ),
                        if (controller.appliedDiscount.value > 0) ...[
                          SizedBox(height: 10),
                          _buildReadOnlyRow(
                            'Discount (${controller.appliedDiscount.value.toInt()}%)',
                            '-₹${controller.discountValue.value.toInt()}',
                            valueColor: Color(0xff16A34A),
                          ),
                          SizedBox(height: 10),
                          Divider(color: Color(0xffE5E7EB), height: 1),
                          SizedBox(height: 10),
                          _buildReadOnlyRow(
                            'Total Amount',
                            '₹${controller.finalAmount.value.toInt()}',
                            isBold: true,
                            valueColor: Color(0xff851653),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 18),

            // ── 3. Paid Amount (editable) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomField(
                keyboardType: TextInputType.number,
                isPoint: true,
                controller: controller.paidAmountController,
                lable: 'Paid Amount',
                hintText: 'Enter the amount you\'ve paid',
                onChange: (_) => controller.recalculateRemainingAmount(_amountOwed),
              ),
            ),
            SizedBox(height: 18),

            // ── 4. Coupon code — hidden when paying off a pending balance ──
            if (!widget.isPendingPayment)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomField(
                              controller: controller.couponCodeController,
                              lable: 'Coupon Code',
                              hintText: 'Enter coupon code',
                            ),
                          ),
                          SizedBox(width: 10),
                          controller.appliedCouponCode.value.isNotEmpty
                              ? SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () => controller.removeCoupon(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xffFEF6FB),
                                      foregroundColor: Color(0xff851653),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Color(0xff851653),
                                        ),
                                      ),
                                    ),
                                    child: Text('Remove'),
                                  ),
                                )
                              : SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed:
                                        controller.isCouponValidating.value
                                        ? null
                                        : () => controller
                                              .validateAndApplyCoupon(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xff851653),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: controller.isCouponValidating.value
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text('Apply'),
                                  ),
                                ),
                        ],
                      ),
                      if (controller.couponMessage.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CustomText(
                            text: controller.couponMessage.value,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: controller.couponSuccess.value
                                ? Color(0xff16A34A)
                                : Color(0xffDC2626),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (!widget.isPendingPayment) SizedBox(height: 18),

            // ── 5. Remaining amount — auto-calculated, never typed ─────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                final remaining = controller.remainingAmount.value;
                final isCleared = remaining <= 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCleared ? Color(0xffF0FDF4) : Color(0xffFEF6FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCleared ? Color(0xffBBF7D0) : Color(0xffFCE7F6),
                    ),
                  ),
                  child: _buildReadOnlyRow(
                    'Remaining Amount',
                    '₹${_formatAmount(remaining)}',
                    isBold: true,
                    valueColor: isCleared ? Color(0xff16A34A) : Color(0xff851653),
                  ),
                );
              }),
            ),

            // ── 6. When to expect the rest — only when something's left ─
            Obx(() {
              if (controller.remainingAmount.value <= 0) {
                return const SizedBox.shrink();
              }
              final now = DateTime.now();
              return Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DatePickerField(
                    label: 'When will the pending amount be paid?',
                    controller: controller.pendingPaymentDateController,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 90)),
                  ),
                ),
              );
            }),

            // Mandatory: proof image, paid amount, and (only when something's
            // left owing) the pending-payment date - see
            // HomeController._evaluateCanSubmitPayment. The button stays
            // disabled rather than only erroring on tap.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Obx(
                () => CustomButton(
                  isLoading: controller.paymentInfoSending.value,
                  enabled: controller.canSubmitPayment.value,
                  onTap: controller.sendPaymentInfo,
                  text: 'Send Payment Details',
                  isOutline: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
