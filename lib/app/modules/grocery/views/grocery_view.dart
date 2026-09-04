import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:docwellness/app/modules/grocery/widgets/greens_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/grocery_controller.dart';

class GroceryView extends StatelessWidget {
  const GroceryView({super.key});

  static const _accent = Color(0xff851653);

  @override
  Widget build(BuildContext context) {
    final GroceryController controller = Get.find<GroceryController>();

    return Obx(() {
      // Tabs are data-driven (see GroceryController.categories) - the tab
      // count can change once, right after the grocery list finishes
      // loading (placeholder ['All'] -> real categories). Keying on the
      // joined tab list forces DefaultTabController to rebuild its
      // TabController when that happens, since TabController's length is
      // otherwise immutable once created.
      final tabs = controller.categories.toList();

      return DefaultTabController(
        length: tabs.length,
        key: ValueKey(tabs.join('|')),
        child: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            tabController.addListener(() {
              if (!tabController.indexIsChanging) {
                controller.filterByCategory(tabs[tabController.index]);
              }
            });

            return Scaffold(
              backgroundColor: Colors.white,

              appBar: AppBar(
                backgroundColor: const Color(0xffFDF2FA),
                elevation: 0,
                // A primary bottom-nav destination - never a back arrow,
                // even when it was reached via a push that leaves a
                // Navigator entry behind it (see diet_and_exercise_screen's
                // same fix).
                automaticallyImplyLeading: false,
                title: Text(
                  "Grocery List",
                  style: GoogleFonts.roboto(
                    color: const Color(0xff1F2A37),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                centerTitle: false,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _WeekDropdown(controller: controller),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(58),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ButtonsTabBar(
                          radius: 8,
                          height: 42,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          backgroundColor: const Color(0xffFCCEEF),
                          borderWidth: 1,
                          borderColor: const Color(0xffFCCEEF),
                          labelStyle: GoogleFonts.roboto(
                            color: const Color(0xff530630),
                            fontWeight: FontWeight.w500,
                          ),
                          unselectedLabelStyle: GoogleFonts.roboto(
                            color: const Color(0xff4D5761),
                            fontWeight: FontWeight.w500,
                          ),
                          unselectedBorderColor: const Color(0xffD2D6DB),
                          unselectedDecoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: const Color(0xffD2D6DB),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tabs: tabs.map((t) => Tab(text: t)).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              body: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff6A0D33),
                    ),
                  );
                }

                if (controller.error.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.error.value,
                          style: const TextStyle(color: Color(0xff6C737F)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: controller.fetchGroceries,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.readyWeeks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Your grocery list isn\'t ready yet - check back once your dietician finalizes this week\'s diet plan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xff6C737F)),
                      ),
                    ),
                  );
                }

                if (controller.filteredItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'No items for this category',
                      style: TextStyle(color: Color(0xff6C737F)),
                    ),
                  );
                }

                return TabBarView(
                  children: List.generate(tabs.length, (tabIdx) {
                    return ListView.builder(
                      itemCount: controller.filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = controller.filteredItems[index];
                        return GroceryTile(
                          item: item,
                          onTogglePurchased: () =>
                              controller.togglePurchased(index),
                        );
                      },
                    );
                  }),
                );
              }),
            );
          },
        ),
      );
    });
  }
}

/// Week selector for the grocery list - only weeks the dietician has
/// actually finalized appear (see GroceryController.readyWeeks); switching
/// is a pure client-side swap since every ready week's items were already
/// prefetched by fetchGroceries(). Styled as a filled brand-accent pill
/// (matching the "GOLDEN"/"FULLY PAID" status chips and the selected-tab
/// fill elsewhere in the app) so it reads as one compact action sitting in
/// the AppBar's title row, rather than the plain white-bordered dropdown
/// this used to be as its own row below the title.
class _WeekDropdown extends StatelessWidget {
  final GroceryController controller;
  const _WeekDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final weeks = controller.readyWeeks;
      if (weeks.isEmpty) return const SizedBox.shrink();
      final selected = weeks.contains(controller.selectedWeek.value)
          ? controller.selectedWeek.value
          : weeks.first;

      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: GroceryView._accent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selected,
            isDense: true,
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 20,
            ),
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            selectedItemBuilder: (context) => weeks
                .map(
                  (w) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Week $w',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            items: weeks
                .map(
                  (w) => DropdownMenuItem(
                    value: w,
                    child: Text(
                      'Week $w',
                      style: GoogleFonts.roboto(
                        color: const Color(0xff1F2A37),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (w) {
              if (w != null) controller.switchWeek(w);
            },
          ),
        ),
      );
    });
  }
}
