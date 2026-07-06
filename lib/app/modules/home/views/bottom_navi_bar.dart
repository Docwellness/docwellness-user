import 'package:docwellness/app/modules/Progress/views/progress_view.dart';
import 'package:docwellness/app/modules/diet/views/diet_view.dart';
import 'package:docwellness/app/modules/grocery/views/grocery_view.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/views/home_view.dart';
import 'package:docwellness/app/modules/profile/views/profile_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const maroonColor = Color(0xff851653);
const lightPink = Color(0xffFEF6FB);

class BottomNaviBar extends StatelessWidget {
  BottomNaviBar({super.key});

  final controller = Get.find<HomeController>();

  final icons = [
    'assets/icons/home.png',
    'assets/icons/Frame.png',
    'assets/icons/Frame(1).png',
    'assets/icons/Frame(2).png',
    'assets/icons/profile.png',
  ];

  final labels = ["Home", "Progress", "Diet", "Grocery", "Profile"];

  /// Build screens lazily - only when the tab is selected
  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeView();
      case 1:
        return const ProgressView();
      case 2:
        return DietPlanScreen();
      case 3:
        return const GroceryView();
      case 4:
        return const ProfileView();
      default:
        return HomeView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: lightPink,
        body: _buildScreen(controller.selectedIndex.value),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: const BoxDecoration(
            color: lightPink,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(icons.length, (index) {
              final isSelected = controller.selectedIndex.value == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    controller.onTabSelected(index);
                    controller.changeTab(index);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 6,
                          bottom: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? maroonColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          icons[index],
                          height: 22,
                          colorBlendMode: BlendMode.srcIn,
                          color: isSelected ? Colors.white : Color(0xff4D5761),
                        ),
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        text: labels[index],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13.5,
                        color: isSelected ? maroonColor : Color(0xff4D5761),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
