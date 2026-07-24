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

  // Lazily built, then kept alive via IndexedStack (AI_EXECUTION_PLAN.md
  // Phase 6, P6-03) - previously each tab switch called _buildScreen(index)
  // inside the Obx below, which constructed a brand-new widget subtree
  // every time (destroying scroll position, form state, and re-firing every
  // initState - see DietPlanScreen's initState, which re-fetched the diet
  // plan on every single tap of the Diet tab as a result; see diet_view.dart
  // for the other half of that fix, P6-04).
  //
  // A plain eager `[HomeView(), ProgressView(), ...]` list would fix state
  // preservation but also build (and fire the initState/fetch of) every
  // tab immediately when the bottom nav first mounts, instead of only the
  // tabs the patient actually visits - a real behavior change this app
  // doesn't need. So each slot starts null and is only constructed the
  // first time its index is selected; IndexedStack itself is what then
  // keeps it mounted (and its State alive) for every subsequent switch.
  final List<Widget?> _screens = List<Widget?>.filled(5, null);

  Widget _screenAt(int index) {
    return _screens[index] ??= switch (index) {
      0 => HomeView(),
      1 => const ProgressView(),
      2 => DietPlanScreen(),
      3 => const GroceryView(),
      4 => const ProfileView(),
      _ => HomeView(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: lightPink,
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: List.generate(_screens.length, (index) {
            // Not visited yet - cheap placeholder, no fetch/state to lose.
            if (index != controller.selectedIndex.value &&
                _screens[index] == null) {
              return const SizedBox.shrink();
            }
            return _screenAt(index);
          }),
        ),
        // SafeArea (not a fixed bottom padding) so this clears whichever
        // system navigation style is active - the 3-button nav bar's ~48dp
        // inset and gesture nav's slimmer inset are both reported through
        // MediaQuery's padding, which SafeArea reads automatically. Apps
        // targeting Android 15+ render edge-to-edge by default, so without
        // this the system nav bar draws on top of - not below - this Row.
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
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
                            color: isSelected
                                ? maroonColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(
                            icons[index],
                            height: 22,
                            colorBlendMode: BlendMode.srcIn,
                            color: isSelected
                                ? Colors.white
                                : Color(0xff4D5761),
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
      ),
    );
  }
}
