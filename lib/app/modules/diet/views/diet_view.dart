import 'package:docwellness/app/models/active_diet_plan_model.dart';
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/diet/views/recipe_details_screen.dart';
import 'package:docwellness/app/modules/home/widgets/food_card.dart';
import 'package:docwellness/app/modules/home/widgets/log_meal_sheet.dart';
import 'package:docwellness/app/modules/home/widgets/no_diet_widget.dart';
import 'package:docwellness/app/services/chat_service.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:docwellness/utils/functions/screenshot_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DietController controller = Get.find<DietController>();
  final GlobalKey _captureKey = GlobalKey();

  // One ScrollController per tab so scroll-and-stitch works for active tab
  late final List<ScrollController> _tabScrollControllers;
  int _activeTabIndex = 0;

  // 7 real serving times + Supplements (a dedicated tab, see
  // DietController.getSupplementRecipes - a supplement otherwise sits
  // anonymously, with zeroed macros, inside whatever real servingTime slot
  // it was assigned to).
  static const int _tabCount = 8;

  // Day strip (~36) + week selector (~48) + TabBar (~48), plus breathing
  // room - the old fixed 100 was too short for all three rows (they need
  // ~132), so the TabBar was being squeezed/clipped instead of laid out at
  // its natural height. 148 (a 16px margin) was still occasionally ~2px
  // short under slightly different font-rendering (RenderFlex overflow on
  // real devices) - these estimated per-row heights are inherently
  // approximate, so the margin needs enough headroom to absorb that, not
  // just the bare minimum.
  static const double _appBarBottomHeight = 160;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabScrollControllers = List.generate(_tabCount, (_) => ScrollController());
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
    // Always refresh diet data when the screen is opened
    controller.getActiveDiet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final sc in _tabScrollControllers) {
      sc.dispose();
    }
    super.dispose();
  }

  /// A tappable Mon-Sun strip for the current calendar week - tapping a day
  /// re-fetches that day's actual planned meals (see
  /// getActiveDietPlanForPatient's day-group filtering in
  /// dietController.js). Browsing is bounded to this week (see
  /// DietController.isDateInCurrentWeek) since a day-group only resolves
  /// within "this week's" 4-group cycle - the Week 1-4 selector below is
  /// for the diet plan's own week blocks. Selecting a future day is a
  /// preview only - Log Meal/Report Allergies hide for it (see
  /// isSelectedDateFuture in _buildDietContent).
  ///
  /// Styling by real calendar day-type (independent of which day is
  /// selected): today keeps the existing solid-pink selected look; a
  /// selected future day gets a dashed pink border instead (a preview, not
  /// really "active" yet); a past day is always grayed out, selected or
  /// not, since it's already history.
  Widget _buildWeekDayStrip() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return Obx(() {
      final weekStart = controller.currentWeekStart;
      final selected = controller.selectedDate.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: List.generate(7, (i) {
            final day = weekStart.add(Duration(days: i));
            final isSelected =
                day.year == selected.year &&
                day.month == selected.month &&
                day.day == selected.day;
            final isPast = day.isBefore(todayOnly);
            final isToday = day.isAtSameMomentAs(todayOnly);
            final isFuture = day.isAfter(todayOnly);

            // Today/future days that aren't selected get the same
            // bordered-card look as the home screen's action cards
            // (see actionContainer in home_view.dart: FEF6FB fill,
            // 9F1561 border) instead of sitting as bare text.
            final isDefaultBox = !isPast && !isSelected;

            Widget cell = Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isPast
                    ? (isSelected
                          ? const Color(0xff9DA4AE)
                          : const Color(0xffF3F4F6))
                    : (isToday && isSelected)
                    ? const Color(0xff851653)
                    : (isFuture && isSelected)
                    ? const Color(0xffFCE7F6)
                    : const Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(8),
                border: isPast
                    ? Border.all(color: const Color(0xff9DA4AE))
                    : isDefaultBox
                    ? Border.all(color: const Color(0xff9F1561))
                    : null,
              ),
              child: CustomText(
                text: labels[i],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isPast
                    ? (isSelected
                          ? const Color(0xffF3F4F6)
                          : const Color(0xff9DA4AE))
                    : (isToday && isSelected)
                    ? Colors.white
                    : (isFuture && isSelected)
                    ? const Color(0xff851653)
                    : const Color(0xff6C737F),
              ),
            );

            // A selected future day gets a dashed pink border instead of a
            // plain one - Flutter has no built-in dashed border, hence the
            // small CustomPaint below (see _DashedRoundedRectPainter).
            // Uses foregroundPainter (not painter) so the dashes are drawn
            // on top of the cell's own opaque fill - drawing them
            // underneath meant the fill (which has no vertical margin to
            // create a gap) painted right over the top/bottom dashes,
            // cropping them away and leaving only the side dashes visible.
            if (isFuture && isSelected) {
              cell = CustomPaint(
                foregroundPainter: _DashedRoundedRectPainter(
                  color: const Color(0xff851653),
                  radius: 8,
                ),
                child: cell,
              );
            }

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.switchDate(day),
                child: cell,
              ),
            );
          }),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.showActiveDietPlanLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Show "No diet assigned" when there's no active diet plan
      if (controller.activeDietData == null) {
        return const NoDietWidget();
      }

      return _buildDietContent();
    });
  }

  Widget _buildDietContent() {
    return RepaintBoundary(
      key: _captureKey,
      child: Scaffold(
        backgroundColor: Colors.white,

        // ---------------- APP BAR ----------------
        appBar: AppBar(
          backgroundColor: const Color(0xffFDF2FA),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const CustomText(
            text: "Diet Plan",
            color: Color(0xff1F2A37),
            fontWeight: FontWeight.w400,
            fontSize: 20,
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () {
                final statusBarH = MediaQuery.of(context).padding.top;
                // AppBar title height + day strip + week selector + tabs
                // (PreferredSize _appBarBottomHeight)
                final totalAppBarH =
                    kToolbarHeight + statusBarH + _appBarBottomHeight;
                ScreenshotHelper.showShareDownloadSheet(
                  context: context,
                  captureKey: _captureKey,
                  scrollController: _tabScrollControllers[_activeTabIndex],
                  appBarHeight: totalAppBarH,
                  filePrefix: 'diet_plan',
                  shareText: 'My diet plan from Docwellness',
                );
              },
              icon: const Icon(Icons.share, color: Color(0xff4D5761)),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(_appBarBottomHeight),
            child: Column(
              children: [
                _buildWeekDayStrip(),
                // ---- WEEK SELECTOR ----
                Obx(() {
                  final current = controller.selectedWeek.value;
                  final total = controller.totalWeeks.value;
                  return Container(
                    color: const Color(0xffFEF6FB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: List.generate(total, (i) {
                        final weekNum = i + 1;
                        final isSelected = weekNum == current;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => controller.switchWeek(weekNum),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xff851653)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xff851653),
                                  width: 1,
                                ),
                              ),
                              child: CustomText(
                                text: 'Week $weekNum',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xff851653),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
                // ---- MEAL TABS ----
                Container(
                  color: const Color(0xffFEF6FB),
                  child: TabBar(
                    isScrollable: true,
                    controller: _tabController,
                    tabAlignment: TabAlignment.start,
                    // Trailing breathing room so the last tab doesn't sit
                    // flush against the screen edge.
                    padding: const EdgeInsets.only(right: 16),
                    labelColor: const Color(0xff851653),
                    unselectedLabelColor: const Color(0xff4D5761),
                    indicatorColor: const Color(0xff851653),
                    labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: "Breakfast"),
                      Tab(text: "Morning Drink"),
                      Tab(text: "Lunch"),
                      Tab(text: "Brunch"),
                      Tab(text: "Dinner"),
                      Tab(text: "Evening Snacks"),
                      Tab(text: "Night Drink"),
                      Tab(text: "Supplements"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ---------------- TAB CONTENT ----------------
        body: TabBarView(
          controller: _tabController,
          children: [
            buildFoodList("Breakfast", 0),
            buildFoodList("Morning Drink", 1),
            buildFoodList("Lunch", 2),
            buildFoodList("Brunch", 3),
            buildFoodList("Dinner", 4),
            buildFoodList("Evening Snack", 5),
            buildFoodList("Night Drink", 6),
            buildSupplementList(7),
          ],
        ),

        // ---------------- BOTTOM BUTTONS ----------------
        // Logging only makes sense for today/past days - hidden entirely
        // (not just disabled) when previewing a future day via the day
        // strip, since there's nothing to log or report yet.
        bottomNavigationBar: Obx(() {
          if (controller.isSelectedDateFuture) return const SizedBox.shrink();
          return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                            return LogMealSheet(
                              scrollController: scrollController,
                            );
                          },
                        );
                      },
                    );
                  },
                  text: 'Log Meal',
                  isOutline: false,
                  fontSize: 15,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  onTap: () => _showReportAllergiesSheet(context),
                  text: 'Report Allergies',
                  isOutline: true,
                  fontSize: 15,
                ),
              ],
            ),
          ),
        );
        }),
      ),
    );
  }

  void _showReportAllergiesSheet(BuildContext context) {
    final textController = TextEditingController();
    final isSending = ValueNotifier(false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Report Allergies',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff1F2A37),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Describe your allergies and your dietician will be notified.',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: const Color(0xff6B7280),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. I am allergic to peanuts, dairy...',
                  hintStyle: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xff9CA3AF),
                  ),
                  filled: true,
                  fillColor: const Color(0xffFEF6FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffFCE7F6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffFCE7F6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xff851653)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: isSending,
                builder: (_, sending, __) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: sending
                          ? null
                          : () async {
                              final text = textController.text.trim();
                              if (text.isEmpty) return;
                              isSending.value = true;
                              await _sendAllergyReport(text);
                              isSending.value = false;
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff851653),
                        disabledBackgroundColor: const Color(0xffBE7BA4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: sending
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Send',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendAllergyReport(String allergyText) async {
    try {
      final chatService = ChatService();

      // Get or create conversation with dietician (auto-routes to assigned doctor)
      final conversation = await chatService.getOrCreateConversation('');
      if (conversation == null) {
        showAppToast(
          Get.overlayContext!,
          message: 'Could not connect to your dietician. Please try again.',
          type: AppToastType.error,
        );
        return;
      }

      final sent = await chatService.sendMessage(
        conversationId: conversation.id,
        receiverId: conversation.doctorId,
        content: allergyText,
        messageType: 'allergy_report',
        metadata: {'allergyText': allergyText},
      );

      if (sent != null) {
        showAppToast(
          Get.overlayContext!,
          message: 'Your allergy report has been sent to your dietician.',
          type: AppToastType.success,
        );
      } else {
        showAppToast(
          Get.overlayContext!,
          message: 'Failed to send. Please try again.',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      showAppToast(
        Get.overlayContext!,
        message: 'Something went wrong. Please try again.',
        type: AppToastType.error,
      );
    }
  }

  // ------------------- BUILD FOOD LIST (Your Mapping Added Here) -------------------
  Widget buildFoodList(String servingTime, int tabIndex) {
    return _buildRecipeListView(
      controller.getRecipesForServing(servingTime),
      tabIndex,
    );
  }

  // Recipes tagged 'supplement' across every slot for the selected day -
  // see DietController.getSupplementRecipes.
  Widget buildSupplementList(int tabIndex) {
    return _buildRecipeListView(controller.getSupplementRecipes(), tabIndex);
  }

  Widget _buildRecipeListView(List<Recipe> recipes, int tabIndex) {
    if (recipes.isEmpty) {
      return Center(child: Text("No recipes available"));
    }

    return ListView.builder(
      controller: _tabScrollControllers[tabIndex],
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FoodCard(
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
                      return RecipeDetailsScreen(
                        scrollController: scrollController,
                        recipe: recipe,
                      );
                    },
                  );
                },
              );
            },
            image: recipe.image,
            name: recipe.name,
            gram: recipe.servingSize.quantity.round().toString(),
            unit: recipe.servingSize.unit,
            calorie: recipe.nutritionPerServing.calories.round().toString(),
            protein: recipe.nutritionPerServing.protein.round().toString(),
            carbs: recipe.nutritionPerServing.carbs.round().toString(),
            fat: recipe.nutritionPerServing.fats.round().toString(),
            fiber: recipe.nutritionPerServing.fiber.round().toString(),
            supplementNutrientLabels: recipe.supplementFacts?.nutrients
                .map((n) => n.displayLabel)
                .toList(),
          ),
        );
      },
    );
  }
}

/// Flutter has no built-in dashed border, so a selected future day (see
/// _buildWeekDayStrip) uses this to paint one instead of pulling in a
/// package for a single small UI element.
class _DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double _strokeWidth = 1.5;
  static const double _dashWidth = 4;
  static const double _dashGap = 3;

  _DashedRoundedRectPainter({required this.color, this.radius = 8});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final segment = draw ? _dashWidth : _dashGap;
        final end = (distance + segment).clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, end), paint);
        }
        distance = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
