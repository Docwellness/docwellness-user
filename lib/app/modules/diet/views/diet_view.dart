import 'package:docwellness/app/models/active_diet_plan_model.dart';
import 'package:docwellness/app/models/timeline_models.dart' show goalTaskIconMap;
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/diet/views/recipe_details_screen.dart';
import 'package:docwellness/app/modules/goal_journey/widgets/blink_pulse.dart';
import 'package:docwellness/app/modules/home/widgets/diet_starts_soon_widget.dart';
import 'package:docwellness/app/modules/home/widgets/food_card.dart';
import 'package:docwellness/app/modules/home/widgets/log_meal_sheet.dart';
import 'package:docwellness/app/modules/home/widgets/no_diet_widget.dart';
import 'package:docwellness/app/services/chat_service.dart';
import 'package:docwellness/shared/widgets/app_empty_state.dart';
import 'package:docwellness/shared/widgets/app_error_state.dart';
import 'package:docwellness/shared/widgets/app_loader.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DietPlanScreen extends StatefulWidget {
  // Optional replacement for the AppBar title - DietAndExerciseScreen passes
  // its Diet Plan/Exercises pill switcher here so this screen's own AppBar
  // becomes the combined tab's single header instead of stacking a second
  // one above it. Null in any other context (there currently isn't one -
  // this is the bottom nav's only entry point to this screen) and falls
  // back to the plain "Diet Plan" title.
  final Widget? headerSwitcher;
  const DietPlanScreen({super.key, this.headerSwitcher});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  final DietController controller = Get.find<DietController>();

  // The whole day's meals now live on one vertical scroll (see build's
  // timeline body) instead of 7+1 separate tabs - one shared controller,
  // and a key per section so an outside "jump to X" request (see
  // focusTabRequest below) can scroll to it.
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    for (final s in _servingOrder) s: GlobalKey(),
    'Supplements': GlobalKey(),
  };
  Worker? _focusTabWorker;

  static const List<String> _servingOrder = [
    'Morning Drink',
    'Breakfast',
    'Brunch',
    'Lunch',
    'Evening Snack',
    'Dinner',
    'Night Drink',
  ];

  // Combined week/day row, plus a modest buffer for font-scaling headroom
  // (RenderFlex overflow has bitten this exact PreferredSize before under
  // slightly different font-rendering on real devices). Kept close to the
  // real content height on purpose: AppBar internally lays out [toolbar,
  // bottom] in a Column with mainAxisAlignment.spaceBetween (see
  // framework's app_bar.dart build()), so any slack here beyond the bottom
  // content's actual height renders as a visible gap between the toolbar
  // (our pill switcher) and this row, not as trailing whitespace below it.
  static const double _appBarBottomHeight = 66;

  @override
  void initState() {
    super.initState();
    // See DietController.focusTabRequest's doc comment - answers a request
    // to jump here from outside (e.g. Supplements tap in the Goal Journey
    // sheet). Index 0-6 map to _servingOrder, 7 means Supplements - same
    // contract external callers (e.g. milestone_sheet.dart) already used
    // for the old TabController, now driving a scroll-to instead of a tab
    // switch.
    _focusTabWorker = ever<int>(controller.focusTabRequest, (index) {
      if (index < 0 || index > _servingOrder.length) return;
      final key = index == _servingOrder.length ? 'Supplements' : _servingOrder[index];
      final context = _sectionKeys[key]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      controller.focusTabRequest.value = -1;
    });
    // Diet data is fetched by DietController.onInit() (once, at login) and
    // refreshed by HomeController.onTabSelected(2) on every tap of the Diet
    // tab (see bottom_navi_bar.dart) - this initState used to also call
    // getActiveDiet() itself, which meant every tap fired it twice at once
    // (AI_EXECUTION_PLAN.md Phase 6, P6-04: "do not fetch diet plan in both
    // controller.onInit() and initState() - use one source"). Now that the
    // bottom nav keeps this screen alive via IndexedStack instead of
    // rebuilding it per tap (P6-03), this initState only runs once per app
    // session anyway, so it was never a real "refresh on visit" path to
    // begin with - onTabSelected already owns that.
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusTabWorker?.dispose();
    super.dispose();
  }

  /// A tappable 7-day strip for the plan's current week (anchored to
  /// DietController.currentWeekStart, i.e. the plan's own weekStartDate, not
  /// necessarily calendar Monday) - tapping a day re-fetches that day's
  /// actual planned meals (see
  /// getActiveDietPlanForPatient's day-group filtering in
  /// dietController.js). Browsing is bounded to this week (see
  /// DietController.isDateInCurrentWeek) since a day-group only resolves
  /// within "this week's" 4-group cycle. A fully-logged past week collapses
  /// to a single "Week N" chip (see DietController.weekCompletion) so the
  /// row doesn't force the patient to scroll past weeks of history just to
  /// reach today - tapping it re-expands that week's 7 days inline, wrapped
  /// in a dashed grey border to mark it as a completed week being
  /// reviewed rather than the live/active one. Every other week (not
  /// selected, or selected but incomplete) shows as normal - see
  /// _buildWeekRow below, which is what actually assembles this into one
  /// scrollable row alongside the week chips.
  ///
  /// Styling by real calendar day-type (independent of which day is
  /// selected): today keeps the existing solid-pink selected look; a
  /// selected future day gets a dashed pink border instead (a preview, not
  /// really "active" yet); a past day is always grayed out, selected or
  /// not, since it's already history.
  Widget _buildDayCells(DateTime weekStart, DateTime selected, {bool expand = false}) {
    // Weekday label keyed by DateTime.weekday (1=Mon..7=Sun) - the strip's 7
    // cells no longer always land on a calendar Mon-Sun grid (see
    // DietController.currentWeekStart), so the label has to be read off
    // each cell's actual date instead of assumed from its position.
    const weekdayLabels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
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
          width: expand ? null : _dayCellWidth,
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
          child: Builder(
            builder: (_) {
              // Same weekday+day-number stacked layout as the Exercise
              // screen's day strip (see exercise_view.dart's _DayStrip) -
              // kept visually consistent between the two, this cell's own
              // color/selection logic above is untouched.
              final cellColor = isPast
                  ? (isSelected ? const Color(0xffF3F4F6) : const Color(0xff9DA4AE))
                  : (isToday && isSelected)
                  ? Colors.white
                  : (isFuture && isSelected)
                  ? const Color(0xff851653)
                  : const Color(0xff6C737F);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: weekdayLabels[day.weekday] ?? '',
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: cellColor,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    text: '${day.day}',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: cellColor,
                  ),
                ],
              );
            },
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

        final tappable = GestureDetector(
          onTap: () => controller.switchDate(day),
          child: cell,
        );
        return expand ? Expanded(child: tappable) : tappable;
      }),
    );
  }

  static const double _dayCellWidth = 44;

  /// One scrollable row combining the week selector and the day strip
  /// (previously two separate rows) - each week is either a compact
  /// "Week N" chip (tap to select it, or to re-expand it if it's the
  /// selected week and complete) or, for the selected week when it's not
  /// complete (the normal/active case) or manually re-expanded, its 7 real
  /// day cells.
  Widget _buildWeekRow() {
    return Obx(() {
      final total = controller.totalWeeks.value;
      final currentWeek = controller.selectedWeek.value;
      final expandedWeek = controller.expandedWeek.value;
      final weekStart = controller.currentWeekStart;
      final selectedDate = controller.selectedDate.value;

      Widget weekChip(int weekNum, {required bool isComplete}) {
        final isSelected = weekNum == currentWeek;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (!isSelected) {
                controller.switchWeek(weekNum);
              } else {
                controller.toggleExpandWeek(weekNum);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xff851653) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xff851653), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: 'Week $weekNum',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xff851653),
                  ),
                  if (isComplete) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xff1F8A5B),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }

      // A single-week plan never shows "Week N" chips at all (the loop
      // below only ever adds one child: the plain, not-complete day-cells
      // branch) - stretch that one row edge-to-edge to match the Diet
      // Plan/Exercises pill switcher above instead of leaving it at its
      // natural (much narrower than the screen) content width inside a
      // horizontally-scrollable row, which is what produced the oversized
      // left/right margins.
      if (total <= 1) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: _buildDayCells(weekStart, selectedDate, expand: true),
        );
      }

      final children = <Widget>[];
      for (var weekNum = 1; weekNum <= total; weekNum++) {
        final isComplete = controller.weekCompletion[weekNum] == true;
        final isCurrent = weekNum == currentWeek;
        final showExpanded =
            isCurrent && (!isComplete || expandedWeek == weekNum);

        if (!showExpanded) {
          children.add(weekChip(weekNum, isComplete: isComplete));
        } else if (isComplete) {
          // Manually re-expanded a completed week to review it - the
          // dashed grey border marks it as "done", distinct from the
          // live/active week's normal (unbordered) styling.
          children.add(
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CustomPaint(
                foregroundPainter: _DashedRoundedRectPainter(
                  color: const Color(0xff9DA4AE),
                  radius: 10,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _buildDayCells(weekStart, selectedDate),
                ),
              ),
            ),
          );
        } else {
          children.add(_buildDayCells(weekStart, selectedDate));
        }
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: children),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read here (not just in the week-pill selector's own nested Obx
      // below) so this outer Obx also rebuilds on a client-side week switch -
      // switchWeek mutates the plain activeDietData field directly, without
      // toggling showActiveDietPlanLoading, specifically to avoid a loading
      // flash - so this is the only Rx this outer scope has to key off of.
      final _ = controller.selectedWeek.value;

      if (controller.showActiveDietPlanLoading.value) {
        return const AppLoader();
      }

      // A fetch failed (network/server error) and there's nothing else to
      // show - distinct from "confirmed no active plan" below (see
      // DietController.getActiveDiet's hasDietLoadError doc comment). If a
      // previous successful fetch left stale data in activeDietData, that
      // takes priority over this - a stale plan is more useful than an
      // error screen on a transient refresh failure.
      if (controller.hasDietLoadError.value &&
          controller.activeDietData == null) {
        return AppErrorState(
          message:
              "Couldn't load your diet plan. Check your connection and try again.",
          onRetry: () => controller.getActiveDiet(),
        );
      }

      // Show "No diet assigned" when there's no active diet plan
      if (controller.activeDietData == null) {
        return const NoDietWidget();
      }

      // The plan exists and is activated, but hasn't actually begun yet
      // (week 1's own start date is in the future - e.g. the dietician
      // picked a future "Starting Date"). Show a countdown instead of live
      // meal content. Deliberately keyed off planStartDate, not
      // weekStartDate - the latter gets overwritten by switchWeek to
      // whichever week the patient is browsing (e.g. Week 2, finalized
      // ahead of time but not due to start for days), and browsing ahead
      // into a not-yet-started future week is an intentional preview, not
      // "the plan hasn't started."
      final planStartDate = controller.activeDietData!.planStartDate;
      if (planStartDate != null && planStartDate.isAfter(DateTime.now())) {
        return DietStartsSoonWidget(startDate: planStartDate);
      }

      return _buildDietContent();
    });
  }

  Widget _buildDietContent() {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // NB: NavigationToolbar always vertically centers the title within
        // the toolbar regardless of any Alignment widget wrapped around it
        // (see widgets/navigation_toolbar.dart's _ToolbarLayout.performLayout,
        // which hardcodes middleY to center) - the gap this screen actually
        // had was between the toolbar and `bottom` below, not within the
        // toolbar itself (see _appBarBottomHeight's own comment).
        title:
            widget.headerSwitcher ??
            const CustomText(
              text: "Diet Plan",
              color: Color(0xff1F2A37),
              fontWeight: FontWeight.w400,
              fontSize: 20,
            ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(_appBarBottomHeight),
          child: _buildWeekRow(),
        ),
      ),

      // ---------------- VERTICAL MEAL TIMELINE ----------------
      // One scrollable column, Morning Drink through Night Drink in order,
      // each with a status dot (logged/missed/upcoming - see
      // _MealTimelineSection) instead of the old 7-tab TabBar+TabBarView -
      // no per-tab switching needed to see the whole day at a glance, same
      // as Goal Journey's own vertical task list.
      body: Obx(() {
        // Read here so the whole timeline rebuilds when the day changes
        // and when logMealData's fetch for it actually lands - logMealData
        // itself is a plain (non-Rx) field (see DietController), so
        // showLogMealLoading flipping false->true->false around its
        // assignment in getLogMeal is what this Obx actually needs to
        // react to; selectedDate.value alone would only catch the
        // synchronous day-switch, not the async fetch completing after it.
        final _ = [controller.selectedDate.value, controller.showLogMealLoading.value];
        final currentServing = controller.currentServingTimeNow;

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            for (final servingTime in _servingOrder)
              _MealTimelineSection(
                key: _sectionKeys[servingTime],
                servingTime: servingTime,
                displayLabel: servingTime == 'Evening Snack' ? 'Evening Snacks' : servingTime,
                isLast: false,
                isLogged: controller.isServingTimeLogged(servingTime),
                isPast: controller.isServingTimePast(servingTime),
                isBlinking: servingTime == currentServing,
                child: _buildFoodColumn(controller.getRecipesForServing(servingTime)),
              ),
            _MealTimelineSection(
              key: _sectionKeys['Supplements'],
              servingTime: 'Supplements',
              displayLabel: 'Supplements',
              isLast: true,
              // Supplements aren't a single time-window with their own log
              // entry (a supplement recipe just rides inside whichever real
              // serving-time slot it was assigned to) - no meaningful
              // logged/missed state of its own, so no status dot at all
              // rather than a fabricated one.
              isLogged: null,
              isPast: false,
              isBlinking: false,
              child: _buildFoodColumn(controller.getSupplementRecipes()),
            ),
          ],
        );
      }),

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
                              // The day currently shown on the day strip -
                              // without this the sheet always logged
                              // whatever "today" was regardless of which
                              // past day the patient was browsing here.
                              initialDate: controller.selectedDate.value,
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

  // ------------------- BUILD FOOD COLUMN -------------------
  // Plain Column, not its own ListView - the whole day's timeline scrolls
  // as one list now (see build's body), so each section just contributes
  // its cards inline instead of owning a separate scroll region.
  Widget _buildFoodColumn(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: AppEmptyState(
          message: 'No recipes for this meal yet.',
          icon: Icons.restaurant_menu_outlined,
        ),
      );
    }

    return Column(
      children: recipes.map((recipe) {
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
            components: recipe.components,
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
      }).toList(),
    );
  }
}

/// Flutter has no built-in dashed border, so a selected future day and a
/// manually re-expanded completed week (see _buildDayCells/_buildWeekRow)
/// use this to paint one instead of pulling in a package for a single small
/// UI element.
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

/// One row of the vertical meal timeline (Morning Drink -> Night Drink,
/// then Supplements) - a status dot + connecting line down to the next
/// section on the left (same green-check/red-exclamation/empty convention
/// as Goal Journey's MilestoneNode, and the same BlinkPulse "this one's
/// happening right now" treatment as its active/today node), the serving
/// time's label and planned recipe card(s) on the right.
class _MealTimelineSection extends StatelessWidget {
  final String servingTime;
  final String displayLabel;
  final bool isLast;
  // null = no meaningful logged/missed state (Supplements - see call site);
  // true/false otherwise.
  final bool? isLogged;
  final bool isPast;
  final bool isBlinking;
  final Widget child;

  const _MealTimelineSection({
    super.key,
    required this.servingTime,
    required this.displayLabel,
    required this.isLast,
    required this.isLogged,
    required this.isPast,
    required this.isBlinking,
    required this.child,
  });

  static const _done = Color(0xff1F8A5B);
  static const _missed = Color(0xffD64545);
  static const _maroon = Color(0xff851653);
  static const _deep = Color(0xff530630);
  static const _upcomingBorder = Color(0xffE9C6DC);
  static const _lineColor = Color(0xffFCE7F6);
  static const double _dotSize = 26;

  static const Map<String, String> _iconKeyByServingTime = {
    'Morning Drink': 'morning_drink',
    'Breakfast': 'breakfast',
    'Brunch': 'brunch',
    'Lunch': 'lunch',
    'Evening Snack': 'evening_snack',
    'Dinner': 'dinner',
    'Night Drink': 'night_drink',
    'Supplements': 'supplements',
  };

  Widget _buildDot() {
    // isLogged == null (Supplements) - a plain neutral dot, same "nothing
    // to report" look as an upcoming slot, just never colored/iconed.
    final missed = isLogged == false && isPast;
    final done = isLogged == true;

    final dot = Container(
      width: _dotSize,
      height: _dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? _done
            : missed
            ? _missed
            : Colors.white,
        border: (done || missed) ? null : Border.all(color: _upcomingBorder, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : missed
          ? const Icon(Icons.priority_high, size: 14, color: Colors.white)
          : null,
    );

    if (!isBlinking) return dot;
    return BlinkPulse(child: dot);
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _dotSize,
            child: Column(
              children: [
                _buildDot(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    // Nudges the label to sit level with the dot's own
                    // center instead of its top edge.
                    padding: const EdgeInsets.only(top: 3, bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          goalTaskIconMap[_iconKeyByServingTime[servingTime]] ??
                              Icons.restaurant_menu,
                          size: 16,
                          color: _maroon,
                        ),
                        const SizedBox(width: 6),
                        CustomText(
                          text: displayLabel,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _deep,
                        ),
                      ],
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
