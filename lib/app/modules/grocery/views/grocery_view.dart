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
                title: Text(
                  "Grocery List",
                  style: GoogleFonts.roboto(
                    color: const Color(0xff1F2A37),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                centerTitle: false,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(108),
                  child: Column(
                    children: [
                      _WeekDropdown(controller: controller),
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
/// prefetched by fetchGroceries().
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

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selected,
                isDense: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: GroceryView._accent,
                ),
                style: GoogleFonts.roboto(
                  color: const Color(0xff1F2A37),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                items: weeks
                    .map(
                      (w) => DropdownMenuItem(
                        value: w,
                        child: Text('Week $w'),
                      ),
                    )
                    .toList(),
                onChanged: (w) {
                  if (w != null) controller.switchWeek(w);
                },
              ),
            ),
          ),
        ),
      );
    });
  }
}
