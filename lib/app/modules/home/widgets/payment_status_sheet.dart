import 'dart:io';

import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentStatusSheet extends StatelessWidget {
  final ScrollController scrollController;

  /// When true (opened from profile), shows the pending amount row
  /// and hides the coupon code section.
  final bool isPendingPayment;
  PaymentStatusSheet({
    super.key,
    required this.scrollController,
    this.isPendingPayment = false,
  });
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final HomeController controller = Get.find<HomeController>();

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
          fontSize: 14,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
          color: valueColor ?? Color(0xff1F2A37),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: formKey,
        child: ListView(
          controller: scrollController,
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
            SizedBox(height: 23),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => GestureDetector(
                  onTap: () => controller.pickPaymentImage(),
                  child: Container(
                    height: 196,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xffFEF6FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: controller.pickedPaymentImage.value == null
                          ? Image.asset('assets/icons/camera.png', height: 48)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(controller.pickedPaymentImage.value!.path),
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Subscription amount (read-only)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadOnlyRow(
                      'Subscription Amount',
                      '₹${HomeController.subscriptionAmount.toInt()}',
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
                ),
              ),
            ),
            SizedBox(height: 16),
            // Show pending amount read-only when opened from profile
            if (isPendingPayment)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => _buildReadOnlyRow(
                    'Pending Amount',
                    '₹${controller.latestAmountPending.value % 1 == 0 ? controller.latestAmountPending.value.toInt() : controller.latestAmountPending.value.toStringAsFixed(2)}',
                    isBold: true,
                    valueColor: const Color(0xff851653),
                  ),
                ),
              ),
            if (!isPendingPayment) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomField(
                  keyboardType: TextInputType.number,
                  controller: controller.pendingAmount,
                  lable: 'Amount Pending',
                ),
              ),
              SizedBox(height: 16),
            ],
            SizedBox(height: 16),

            // Coupon code section — hidden when in pending-payment mode
            if (!isPendingPayment)
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
            SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomField(
                controller: controller.paymentDes,
                lable: 'Description',
                hintText: 'Add few more words for describing your feeling',
                maxLines: 6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Obx(
                () => CustomButton(
                  isLoading: controller.paymentInfoSending.value,
                  onTap: () {
                    if (!isPendingPayment &&
                        controller.pendingAmount.text.trim().isEmpty) {
                      Get.snackbar('Error', 'Please enter amount pending');
                      return;
                    }
                    controller.sendPaymentInfo();
                  },
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
