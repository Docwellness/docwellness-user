import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/diet/views/recipe_details_screen.dart';
import 'package:docwellness/app/modules/home/widgets/food_card.dart';
import 'package:docwellness/app/modules/home/widgets/log_meal_sheet.dart';
import 'package:docwellness/app/modules/home/widgets/no_diet_widget.dart';
import 'package:docwellness/app/services/chat_service.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabScrollControllers = List.generate(7, (_) => ScrollController());
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

  /// A plain Mon-Sun week strip with today highlighted - not a "Mon & Fri
  /// share a diet" grouping (that's an internal generation detail, not
  /// something to surface as the patient's own week view). The backend
  /// already filtered the meals shown below to just today's actual plan
  /// (see getActiveDietPlanForPatient in dietController.js) - this strip is
  /// purely a "here's where today sits in the week" visual cue.
  Widget _buildWeekDayStrip() {
    final todayWeekday = DateTime.now().weekday; // 1=Monday .. 7=Sunday
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: List.generate(7, (i) {
          final isToday = (i + 1) == todayWeekday;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? const Color(0xff851653) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomText(
                text: labels[i],
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday ? Colors.white : const Color(0xff6C737F),
              ),
            ),
          );
        }),
      ),
    );
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
                // AppBar title height + week selector + tabs (PreferredSize 100)
                final totalAppBarH = kToolbarHeight + statusBarH + 100;
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
            preferredSize: const Size.fromHeight(100),
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
          ],
        ),

        // ---------------- BOTTOM BUTTONS ----------------
        bottomNavigationBar: SafeArea(
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
        ),
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
        Get.snackbar(
          'Error',
          'Could not connect to your dietician. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
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
        Get.snackbar(
          'Sent',
          'Your allergy report has been sent to your dietician.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xffD1FAE5),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to send. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  // ------------------- BUILD FOOD LIST (Your Mapping Added Here) -------------------
  Widget buildFoodList(String servingTime, int tabIndex) {
    final recipes = controller.getRecipesForServing(servingTime);

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
            gram:
                "${recipe.servingSize.quantity.round()}${recipe.servingSize.unit.toUpperCase()}",
            calorie: recipe.nutritionPerServing.calories.round().toString(),
            protein: recipe.nutritionPerServing.protein.round().toString(),
            carbs: recipe.nutritionPerServing.carbs.round().toString(),
            fat: recipe.nutritionPerServing.fats.round().toString(),
            fiber: recipe.nutritionPerServing.fiber.round().toString(),
          ),
        );
      },
    );
  }
}
