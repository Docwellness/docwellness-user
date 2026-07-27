import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/views/orders_list_view.dart';
import 'package:docwellness/app/modules/home/widgets/payment_status_sheet.dart';
import 'package:docwellness/app/modules/profile/views/account_view.dart';
import 'package:docwellness/app/modules/profile/views/notification_view.dart';
import 'package:docwellness/app/modules/profile/views/settings_view.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        title: Text(
          'Profile',
          style: GoogleFonts.roboto(
            color: Color(0xff1F2A37),
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 260,
                width: double.infinity,
                color: Color(0xffFEF6FB),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 95,
                      width: 95,
                      child: Stack(
                        children: [
                          Container(
                            height: 85,
                            width: 85,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 3.4,
                              ),
                              borderRadius: BorderRadius.circular(90),
                              color: Color(0xffF3F4F6),
                            ),
                            child: Center(
                              child: controller.profileImage.value.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 35.4,
                                      backgroundImage: CachedNetworkImageProvider(
                                        controller.profileImage.value,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 35.4,
                                      backgroundColor: Color(0xff851653),
                                      child: Text(
                                        controller.fullName.value.isNotEmpty
                                            ? controller.fullName.value[0]
                                                  .toUpperCase()
                                            : 'U',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 10,
                            child: InkWell(
                              onTap: controller.pickAndUploadImage,
                              child: Image.asset(
                                'assets/icons/icon_container.png',
                                height: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5),
                    CustomText(
                      text: controller.fullName.value.isEmpty
                          ? 'User'
                          : controller.fullName.value,
                      color: Color(0xff111927),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 3),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: CustomText(
                        text: controller.primaryGoal.value.isNotEmpty
                            ? "Goal: ${controller.primaryGoal.value}"
                            : controller.email.value,
                        color: Color(0xff4D5761),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        await Get.toNamed(Routes.EDIT_PROFILE);
                        controller.fetchUserProfile();
                      },
                      child: Container(
                        width: 110,
                        padding: EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Color(0xffE5E7EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                color: Color(0xff4D5761),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              CustomText(
                                text: "Edit profile",
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff111927),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: customContainer(
                        title: "Current Weight",
                        value: controller.weight.value > 0
                            ? '${controller.weight.value.toStringAsFixed(1)} kg'
                            : '--',
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: customContainer(
                        title: "Goal Weight",
                        value: controller.targetWeight.value.isNotEmpty
                            ? controller.targetWeight.value
                            : '--',
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: customContainer(
                        title: "Current BMI",
                        value: controller.bmi.value > 0
                            ? controller.bmi.value.toStringAsFixed(1)
                            : '--',
                      ),
                    ),
                  ],
                ),
              ),
              _PendingAmountCard(),
              SizedBox(height: 16),
              customTile(
                icon: 'assets/icons/user_4_line.png',
                text: 'Account',
                onTap: () => Get.to(() => const AccountView()),
              ),
              SizedBox(height: 8),
              customTile(
                icon: 'assets/icons/notification.png',
                text: 'Notification',
                onTap: () => Get.to(() => const NotificationView()),
              ),
              SizedBox(height: 8),
              customTile(
                icon: 'assets/icons/setting.png',
                text: 'Settings',
                onTap: () => Get.to(() => const SettingsView()),
              ),
              SizedBox(height: 8),
              customTile(
                icon: 'assets/icons/book_line.png',
                text: 'Your Orders',
                onTap: () => Get.to(() => const OrdersListView()),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomButton(
                  textColor: Color(0xff851653),
                  outlineButtonColor: Color(0xff851653),
                  onTap: () => controller.logout(),
                  text: 'Log out',
                  isOutline: true,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget customContainer({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: title,

            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xff4D5761),
          ),
          SizedBox(height: 2),
          CustomText(
            text: value,

            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xff111927),
          ),
        ],
      ),
    );
  }

  Widget customTile({
    required String icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xffFEF6FB),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Image(image: AssetImage(icon), height: 20, width: 20),
              SizedBox(width: 14),
              Expanded(
                child: CustomText(
                  text: text,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff111927),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xff9DA4AE),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingAmountCard extends StatelessWidget {
  _PendingAmountCard();

  final HomeController homeController = Get.find<HomeController>();

  void _openPaymentSheet(BuildContext context) {
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
            return PaymentStatusSheet(
              scrollController: scrollController,
              isPendingPayment: true,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pending = homeController.latestAmountPending.value;
      final status = homeController.requestStatus.value;

      // Only show when dietician has requested payment AND there is a pending amount
      if (status != 'PaymentRequested' || pending <= 0)
        return const SizedBox.shrink();

      String fmt(double v) =>
          v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xffFEF6FB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffF9A8D4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      text: 'Payment Due',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff530630),
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      text: 'Pending: ₹${fmt(pending)}',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff851653),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _openPaymentSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff530630),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const CustomText(
                    text: 'Pay',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
