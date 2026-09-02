import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/home/widgets/create_my_food_sheet.dart';
import 'package:docwellness/app/modules/home/widgets/log_meal_container.dart';
import 'package:docwellness/app/services/chat_service.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class LogMealSheet extends StatefulWidget {
  final ScrollController scrollController;
  // Overrides getAutoShiftIndex()'s time-of-day guess - set when arriving
  // here from a specific "Not logged" row (e.g. the Goal Journey sheet) so
  // the sheet opens already focused on that meal instead of whatever the
  // current time would normally pick.
  final String? initialServing;
  // Which day this sheet logs for - passed by callers that already have a
  // specific day in context (e.g. diet_view.dart's day strip, so tapping
  // "Log Meal" while browsing a previous day logs *that* day, not today).
  // Null for entry points with no day context of their own (Home/Progress/
  // Goal Journey's "not logged" rows), which always mean today.
  final DateTime? initialDate;
  const LogMealSheet({
    super.key,
    required this.scrollController,
    this.initialServing,
    this.initialDate,
  });

  @override
  State<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<LogMealSheet> {
  final DietController controller = Get.find<DietController>();
  DateTime? selectedDate;

  // Logging (and the adjacent Create My Food/Confession Box actions) makes
  // sense for today or any already-passed day - only a future day, which
  // hasn't happened yet, has nothing to log. Deliberately not
  // controller.logMealData!.isPresentDate, which is true only for an exact
  // match on today and used to hide/disable logging for every past day too
  // - see diet_view.dart's bottomNavigationBar, which already only shows
  // its own "Log Meal" entry point for today-or-past days.
  bool get _canLog {
    final d = selectedDate ?? DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !day.isAfter(today);
  }

  // A meal can only be logged for today or an already-passed day within the
  // current week (see DietController.isDateLoggable) - you can't log
  // something that hasn't happened yet, and a day-group only resolves
  // within "this week's" 4-group cycle.
  Future<void> pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: controller.currentWeekStart,
      lastDate: today,
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
    await controller.getLogMeal(selectedDate);
  }

  String get formattedDate {
    if (selectedDate == null) {
      return "${DateTime.now().month.toString().padLeft(2, '0')}/"
          "${DateTime.now().day.toString().padLeft(2, '0')}/"
          "${DateTime.now().year}";
    }
    return "${selectedDate!.month.toString().padLeft(2, '0')}/"
        "${selectedDate!.day.toString().padLeft(2, '0')}/"
        "${selectedDate!.year}";
  }

  static const List<String> _weekdayAbbrev = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];

  // DateTime.weekday is 1=Monday..7=Sunday - was previously hardcoded to
  // "Mo." regardless of the actual day, which misled which day a meal was
  // being logged for (e.g. a Tuesday showed as "Mo. 07/14/2026").
  String get weekdayAbbrev {
    final date = selectedDate ?? DateTime.now();
    return _weekdayAbbrev[date.weekday - 1];
  }

  // Matches DietController.currentServingTimeNow's hour ranges exactly -
  // see that getter's doc comment for why Morning Drink comes first and
  // Brunch (late morning) comes before Lunch (early-mid afternoon), not the
  // reverse this used to have.
  int getAutoShiftIndex() {
    final hour = DateTime.now().hour; // 0–23

    if (hour >= 5 && hour < 8) return 0; // Morning Drink
    if (hour >= 8 && hour < 10) return 1; // Breakfast
    if (hour >= 10 && hour < 12) return 2; // Brunch
    if (hour >= 12 && hour < 15) return 3; // Lunch
    if (hour >= 15 && hour < 19) return 4; // Evening Snack
    if (hour >= 19 && hour < 22) return 5; // Dinner (7–10 PM)

    return 6; // Night Drink
  }

  final List<String> servingOrder = const [
    "Morning Drink",
    "Breakfast",
    "Brunch",
    "Lunch",
    "Evening Snack",
    "Dinner",
    "Night Drink",
  ];
  @override
  void initState() {
    selectedDate = widget.initialDate;
    controller.getLogMeal(selectedDate);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.showLogMealLoading.value
          ? Center(child: CircularProgressIndicator())
          : controller.logMealData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_food, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  CustomText(
                    text: 'No diet plan available',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  CustomText(
                    text: 'Please contact your dietician',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ],
              ),
            )
          : _buildLogMealContent(),
    );
  }

  Widget _buildLogMealContent() {
    final requestedIndex =
        widget.initialServing != null ? servingOrder.indexOf(widget.initialServing!) : -1;
    return DefaultTabController(
      initialIndex: requestedIndex >= 0 ? requestedIndex : getAutoShiftIndex(),
      length: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                    ),
                    SizedBox(width: 14),
                    CustomText(
                      text: 'Log Meal',
                      fontWeight: FontWeight.w400,
                      fontSize: 19,
                      color: Color(0xff1F2A37),
                    ),
                  ],
                ),

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1.5,
                        ),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: Color(0xffFCE7F6),
                          border: Border.all(color: Color(0xffEF45B2)),
                        ),
                        child: Center(
                          child: CustomText(
                            text: formattedDate != 'Select date'
                                ? '$weekdayAbbrev. $formattedDate'
                                : formattedDate,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                            color: Color(0xff851653),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: pickDate,
                        child: Image.asset(
                          'assets/icons/log_meal_calendar.png',
                          height: 24,
                          width: 24,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Color(0xffE5E7EB)),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ButtonsTabBar(
                  radius: 8,
                  height: 42,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: const Color(0xffFCCEEF),
                  borderWidth: 1,
                  borderColor: const Color(
                    0xffFCCEEF,
                  ), // selected tab border color (optional)
                  labelStyle: GoogleFonts.roboto(
                    color: Color(0xff530630),
                    fontWeight: FontWeight.w500,
                  ),

                  unselectedLabelStyle: GoogleFonts.roboto(
                    color: Color(0xff4D5761),
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

                  tabs: const [
                    Tab(text: "Morning Drink"),
                    Tab(text: "Breakfast"),
                    Tab(text: "Brunch"),
                    Tab(text: "Lunch"),
                    Tab(text: "Evening Snacks"),
                    Tab(text: "Dinner"),
                    Tab(text: "Night Drink"),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 13),
          Expanded(
            child: TabBarView(
              children: servingOrder.map((serving) {
                final data = controller.getServingTimeByName(serving);

                if (data == null || data.plannedMeals.isEmpty) {
                  return Center(child: Text("No meals"));
                }

                return ListView.builder(
                  itemCount: data.plannedMeals.length,
                  itemBuilder: (context, index) {
                    final meal = data.plannedMeals[index];

                    return LogMealContainer(
                      imageUrl: meal.image,
                      title: meal.name,
                      garam: "${meal.totalWeight}",
                      unit: meal.totalWeightUnit,
                      kcal: "${meal.calories} kcal",
                      index: index,
                      selectedPortion: meal.portion.toString(),
                      isPresentDate: _canLog,
                      servingTime: serving,
                      recipeId: meal.recipeId,
                    );
                  },
                );
              }).toList(),
            ),
          ),
          if (_canLog)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => CustomButton(
                  isLoading: controller.showSendLogMealLoading.value,
                  onTap: () async {
                    await controller.sendLogMeal();
                  },
                  text: 'Submit Logged Meals',
                  isOutline: false,
                  fontSize: 14,
                ),
              ),
            ),
          SizedBox(height: 16),
          if (_canLog)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomButton(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    isScrollControlled: true,

                    useSafeArea: true,
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
                          return CreateMyFoodSheet(
                            scrollController: scrollController,
                          );
                        },
                      );
                    },
                  );
                },

                text: 'Create My Food',
                isOutline: true,
                fontSize: 14,
              ),
            ),
          if (_canLog)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => _showConfessionSheet(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Color(0xffFEF6FB),
                    border: Border.all(color: Color(0xffFDF2FA)),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/Leading element.png',
                        height: 90,
                        width: 90,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: 'Confession Box',
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                              color: Color(0xff384250),
                            ),
                            CustomText(
                              text: 'Confess if you ate any cheat meal',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xff6C737F),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showConfessionSheet(BuildContext context) {
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
                'Confession Box',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff1F2A37),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Confess if you ate any cheat meal. Your dietician will see this.',
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
                  hintText: 'e.g. I had pizza for dinner...',
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
                              await _sendConfession(text);
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
    ).whenComplete(() {
      textController.dispose();
      isSending.dispose();
    });
  }

  Future<void> _sendConfession(String confessionText) async {
    try {
      final chatService = ChatService();
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
        content: confessionText,
        messageType: 'confession_box',
        metadata: {'confessionText': confessionText},
      );

      if (sent != null) {
        await Posthog().capture(eventName: 'confession_sent');
        showAppToast(
          Get.overlayContext!,
          message: 'Your confession has been sent to your dietician.',
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
}
