import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:docwellness/app/modules/grocery/widgets/greens_card.dart';
import 'package:docwellness/utils/functions/screenshot_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/grocery_controller.dart';

class GroceryView extends StatefulWidget {
  const GroceryView({super.key});

  @override
  State<GroceryView> createState() => _GroceryViewState();
}

class _GroceryViewState extends State<GroceryView> {
  final GroceryController controller = Get.find<GroceryController>();
  final GlobalKey _captureKey = GlobalKey();
  // Rebuilt to match controller.categories whenever it changes (see
  // _syncScrollControllers) - one ScrollController per tab, for the
  // scroll-and-stitch screenshot feature.
  List<ScrollController> _tabScrollControllers = [];
  int _activeTabIndex = 0;

  @override
  void dispose() {
    for (final sc in _tabScrollControllers) {
      sc.dispose();
    }
    super.dispose();
  }

  void _syncScrollControllers(int tabCount) {
    if (_tabScrollControllers.length == tabCount) return;
    for (final sc in _tabScrollControllers) {
      sc.dispose();
    }
    _tabScrollControllers = List.generate(tabCount, (_) => ScrollController());
    if (_activeTabIndex >= tabCount) _activeTabIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Tabs are data-driven (see GroceryController.categories) - the tab
      // count can change once, right after the grocery list finishes
      // loading (placeholder ['All'] -> real categories). Keying on the
      // joined tab list forces DefaultTabController to rebuild its
      // TabController when that happens, since TabController's length is
      // otherwise immutable once created.
      final tabs = controller.categories.toList();
      _syncScrollControllers(tabs.length);

      return DefaultTabController(
        length: tabs.length,
        key: ValueKey(tabs.join('|')),
        child: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            tabController.addListener(() {
              if (!tabController.indexIsChanging) {
                controller.filterByCategory(tabs[tabController.index]);
                setState(() => _activeTabIndex = tabController.index);
              }
            });

            return RepaintBoundary(
              key: _captureKey,
              child: Scaffold(
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
                  actions: [
                    IconButton(
                      onPressed: () {
                        final statusBarH = MediaQuery.of(context).padding.top;
                        final totalAppBarH = kToolbarHeight + statusBarH + 60;
                        ScreenshotHelper.showShareDownloadSheet(
                          context: context,
                          captureKey: _captureKey,
                          scrollController:
                              _tabScrollControllers[_activeTabIndex],
                          appBarHeight: totalAppBarH,
                          filePrefix: 'grocery_list',
                          shareText: 'My grocery list from Docwellness',
                        );
                      },
                      icon: const Icon(Icons.share, color: Color(0xff4D5761)),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Padding(
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

                  if (controller.filteredItems.isEmpty) {
                    return const Center(
                      child: Text(
                        'No items for this category',
                        style: TextStyle(color: Color(0xff6C737F)),
                      ),
                    );
                  }

                  // Each tab gets its own ScrollController for scroll-and-stitch
                  return TabBarView(
                    children: List.generate(tabs.length, (tabIdx) {
                      return ListView.builder(
                        controller: _tabScrollControllers[tabIdx],
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
              ),
            );
          },
        ),
      );
    });
  }
}
