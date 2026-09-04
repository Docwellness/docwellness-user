import 'package:docwellness/app/models/active_diet_plan_model.dart';
import 'package:docwellness/app/models/timeline_models.dart'
    show goalTaskIconMap;
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/diet/views/recipe_details_screen.dart';
import 'package:docwellness/app/modules/diet/widgets/quick_log_button.dart';
import 'package:docwellness/app/modules/goal_journey/widgets/blink_pulse.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/widgets/diet_starts_soon_widget.dart';
import 'package:docwellness/app/modules/home/widgets/food_card.dart';
import 'package:docwellness/app/modules/home/widgets/log_meal_sheet.dart';
import 'package:docwellness/app/modules/home/widgets/no_diet_widget.dart';
import 'package:docwellness/app/services/chat_service.dart';
import 'package:docwellness/shared/widgets/app_empty_state.dart';
import 'package:docwellness/shared/widgets/app_error_state.dart';
import 'package:docwellness/shared/widgets/app_loader.dart';
import 'package:docwellness/shared/route_observer.dart';
import 'package:docwellness/shared/widgets/week_day_strip.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// The week/day selector row - week chips (multi-week plans) or a single
/// edge-to-edge day strip (the common single-week case), plus the actual
/// 7-day WeekDayStrip cells. Extracted out of DietPlanScreen so
/// DietAndExerciseScreen can host exactly ONE instance of this in its own
/// AppBar, shared by both the Diet Plan and Exercises pills, instead of
/// each pill building its own separate copy - two independently-built
/// instances of visually-identical-looking widgets is what let their
/// heights/backgrounds silently drift apart in the first place (see the
/// white-Container-height fixes below, both still needed for
/// DietPlanScreen's own standalone-route AppBar).
class DietWeekRow extends StatefulWidget {
  // Optional override for which controller(s) a day tap updates - passed
  // by DietAndExerciseScreen so selecting a day updates both DietController
  // AND ExerciseController's selectedDate together (there's only one day
  // strip now, shared by both pills). Defaults to just DietController's own
  // switchDate for DietPlanScreen's standalone-route case, where there's no
  // Exercises pill to keep in sync with.
  final ValueChanged<DateTime>? onDaySelected;
  const DietWeekRow({super.key, this.onDaySelected});

  // Plus a modest buffer for font-scaling headroom (RenderFlex overflow has
  // bitten this exact PreferredSize before under slightly different
  // font-rendering on real devices). Kept close to the real content height
  // on purpose: AppBar internally lays out [toolbar, bottom] in a Column
  // with mainAxisAlignment.spaceBetween (see framework's app_bar.dart
  // build()), so any slack here beyond the bottom content's actual height
  // renders as a visible gap between the toolbar (the pill switcher) and
  // this row, not as trailing whitespace below it.
  static const double height = 66;

  @override
  State<DietWeekRow> createState() => _DietWeekRowState();
}

class _DietWeekRowState extends State<DietWeekRow> {
  final ScrollController _scrollController = ScrollController();
  // The current/expanded week's day cells - GlobalKey so it can be located
  // for Scrollable.ensureVisible below regardless of how many "Week N"
  // chips scroll past before it.
  final GlobalKey _activeCellsKey = GlobalKey();
  // Guards against re-scrolling on every reactive rebuild (e.g. a meal log
  // ping) once today's cell has already been brought into view for the
  // current week/selected-day combo - re-keyed so switching weeks or
  // browsing to a different day re-triggers it.
  String? _scrolledFor;

  DietController get _controller => Get.find<DietController>();

  // The week chips a multi-week plan shows before the current week's day
  // cells left the current week's cells scrolled off the right edge by
  // default (SingleChildScrollView starts at offset 0) - nothing put
  // today's date on screen without the patient manually scrolling. Runs
  // once per distinct week/day selection, after the frame that actually
  // laid the row out.
  void _scrollActiveIntoView(String selectionKey) {
    if (_scrolledFor == selectionKey) return;
    _scrolledFor = selectionKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _activeCellsKey.currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// A tappable 7-day strip for the plan's current week (anchored to
  /// DietController.currentWeekStart, i.e. the plan's own weekStartDate, not
  /// necessarily calendar Monday) - tapping a day re-fetches that day's
  /// actual planned meals (see getActiveDietPlanForPatient's day-group
  /// filtering in dietController.js). Browsing is bounded to this week (see
  /// DietController.isDateInCurrentWeek) since a day-group only resolves
  /// within "this week's" 4-group cycle. A fully-logged past week collapses
  /// to a single "Week N" chip (see DietController.weekCompletion) so the
  /// row doesn't force the patient to scroll past weeks of history just to
  /// reach today - tapping it re-expands that week's 7 days inline, wrapped
  /// in a dashed grey border to mark it as a completed week being
  /// reviewed rather than the live/active one. Every other week (not
  /// selected, or selected but incomplete) shows as normal - see build
  /// below, which is what actually assembles this into one scrollable row
  /// alongside the week chips.
  Widget _buildDayCells(
    DateTime weekStart,
    DateTime selected, {
    bool expand = false,
  }) {
    return WeekDayStrip(
      weekStart: weekStart,
      selectedDate: selected,
      onDaySelected: widget.onDaySelected ?? _controller.switchDate,
      expand: expand,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Obx(() {
      final total = controller.totalWeeks.value;
      final currentWeek = controller.selectedWeek.value;
      final expandedWeek = controller.expandedWeek.value;
      final weekStart = controller.currentWeekStart;
      final selectedDate = controller.selectedDate.value;

      Widget weekChip(
        int weekNum,
        int displayWeek, {
        required bool isComplete,
      }) {
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
                    text: 'Week $displayWeek',
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
        // White, not the AppBar's own pink (0xffFDF2FA) bleeding through -
        // this row sits in the AppBar's `bottom` slot (so it stays pinned
        // above the scrollable content below), and needs an explicit
        // height matching the slot's own preferredSize - PreferredSize
        // gives its child loose (not tight) height constraints, so without
        // this a Container sized only to its own (shorter) content leaves
        // a residual sliver of the AppBar's pink Material showing through
        // below it.
        return Container(
          width: double.infinity,
          height: DietWeekRow.height,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: _buildDayCells(weekStart, selectedDate, expand: true),
          ),
        );
      }

      // Iterate the real week entries so a renewal's continued weeks
      // (Week 5-8, whose `week` is offset) get the right label from
      // displayWeek. Falls back to a synthetic 1..total list for older
      // cached data that has no `weeks` array.
      final weekEntries =
          controller.activeDietData?.weeks ?? const <WeekEntry>[];
      final entries = weekEntries.isNotEmpty
          ? weekEntries
          : [
              for (var i = 1; i <= total; i++)
                WeekEntry(week: i, dailyMeals: const []),
            ];

      final children = <Widget>[];
      for (final entry in entries) {
        final weekNum = entry.week;
        final displayW = entry.displayWeek;
        final isComplete = controller.weekCompletion[weekNum] == true;
        final isCurrent = weekNum == currentWeek;
        final showExpanded =
            isCurrent && (!isComplete || expandedWeek == weekNum);

        if (!showExpanded) {
          children.add(weekChip(weekNum, displayW, isComplete: isComplete));
        } else if (isComplete) {
          // Manually re-expanded a completed week to review it - the
          // dashed grey border marks it as "done", distinct from the
          // live/active week's normal (unbordered) styling.
          children.add(
            Padding(
              key: _activeCellsKey,
              padding: const EdgeInsets.only(right: 8),
              child: CustomPaint(
                foregroundPainter: DashedRoundedRectPainter(
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
          // Same trailing margin as every weekChip/dashed-completed-week
          // sibling in this row - without it, the live week's last day cell
          // sits flush against whatever "Week N" chip comes right after it.
          children.add(
            Padding(
              key: _activeCellsKey,
              padding: const EdgeInsets.only(right: 8),
              child: _buildDayCells(weekStart, selectedDate),
            ),
          );
        }
      }

      // The current/expanded week's day cells (just keyed above) default to
      // sitting off the right edge of this row behind however many "Week N"
      // chips precede them - bring today's date on screen without the
      // patient having to scroll for it themselves.
      _scrollActiveIntoView(
        '$currentWeek|${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
      );

      // Same white-not-pink, explicit-height override as the single-week
      // branch above.
      return Container(
        width: double.infinity,
        height: DietWeekRow.height,
        color: Colors.white,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: children),
        ),
      );
    });
  }
}

/// The "Log Meal" / "Report Allergies" bottom buttons - extracted out of
/// DietPlanScreen for the same reason as DietWeekRow above: when embedded
/// in DietAndExerciseScreen, the parent's single Scaffold owns this slot
/// (shown only while the Diet Plan pill is active) instead of DietPlanScreen
/// having its own.
class DietBottomActions extends StatelessWidget {
  const DietBottomActions({super.key});

  DietController get _controller => Get.find<DietController>();

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // Logging only makes sense for today/past days - hidden entirely (not
    // just disabled) when previewing a future day via the day strip, since
    // there's nothing to log or report yet.
    return Obx(() {
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
                            // without this the sheet always logged whatever
                            // "today" was regardless of which past day the
                            // patient was browsing here.
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
    });
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
}

class DietPlanScreen extends StatefulWidget {
  // True when hosted inside DietAndExerciseScreen's combined Scaffold (the
  // bottom nav's only real entry point to this screen) - suppresses this
  // screen's own Scaffold/AppBar/day-strip/bottom-buttons entirely and
  // returns just the meal timeline, since the parent now owns one single
  // shared AppBar+day-strip+bottom-buttons for both the Diet Plan and
  // Exercises pills (previously each pill had its own separate AppBar/
  // day-strip instance, which was the actual cause of the two visually
  // drifting apart - two different widgets, not one). False renders the
  // full standalone screen (Routes.DIET_PLAN's direct, currently-unlinked
  // deep-link entry point).
  final bool embedded;
  const DietPlanScreen({super.key, this.embedded = false});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> with RouteAware {
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
  Worker? _tabRevisitWorker;

  // Auto-scrolls to the current (blinking) serving time once per visit to
  // this screen - not on every rebuild (a day switch, a log refreshing
  // logMealData, etc. shouldn't keep yanking the patient back to "now" if
  // they've since scrolled elsewhere themselves within the same visit).
  // Reset to false by _tabRevisitWorker below whenever the bottom nav
  // returns to this tab, since bottom_navi_bar.dart's IndexedStack keeps
  // this screen's State alive across tab switches (see initState's own
  // comment on P6-03) - without that reset this flag, being a plain field
  // rather than Rx, would only ever fire once for the State object's entire
  // lifetime (i.e. once per app session, not once per visit).
  bool _hasAutoScrolledToCurrent = false;

  static const List<String> _servingOrder = [
    'Morning Drink',
    'Breakfast',
    'Brunch',
    'Lunch',
    'Evening Snack',
    'Dinner',
    'Night Drink',
  ];

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
      final key = index == _servingOrder.length
          ? 'Supplements'
          : _servingOrder[index];
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

    // Re-arms the auto-scroll-to-now behavior (see _hasAutoScrolledToCurrent)
    // every time the bottom nav lands back on this tab (index 2), not just
    // the first time this screen is ever built - same IndexedStack-keeps-
    // state-alive reasoning as above. Body's Obx already rebuilds on its own
    // right after (HomeController.onTabSelected(2) calls getActiveDiet(),
    // which reassigns selectedDate.value even to "the same" day - a fresh
    // DateTime.now() call is never == the previous one), so resetting the
    // flag here just needs to happen before that next rebuild picks it up.
    if (Get.isRegistered<HomeController>()) {
      _tabRevisitWorker = ever<int>(Get.find<HomeController>().selectedIndex, (
        index,
      ) {
        if (index == 2 && mounted) {
          setState(() => _hasAutoScrolledToCurrent = false);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribes to the app-wide RouteObserver (see main.dart) so
    // didPopNext() below fires whenever a route pushed ON TOP of this
    // screen's shell gets popped - e.g. viewing Goal Journey (a full-page
    // route, pushed via Get.toNamed) and coming back. That never touches
    // HomeController.selectedIndex at all (the bottom nav's own tab index
    // is unchanged throughout - Goal Journey is a stacked route, not a tab
    // switch), so the initState-registered selectedIndex worker above
    // can't catch it on its own; this covers that gap.
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // A route stacked on top of this screen's shell (Goal Journey, a Log
    // Meal sheet, etc.) was just popped, bringing this screen back into
    // view - re-arm the same auto-scroll-to-now behavior the
    // selectedIndex worker triggers on a bottom-nav tab switch. Harmless to
    // call even while this screen isn't the currently selected tab/pill
    // (IndexedStack still builds offstage children, so the scroll executes
    // quietly and is already in place by the time it's shown again).
    setState(() => _hasAutoScrolledToCurrent = false);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    _focusTabWorker?.dispose();
    _tabRevisitWorker?.dispose();
    super.dispose();
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
        // A refetch (getActiveDiet is called again on every bottom-nav tab
        // switch back to this tab, not just the first visit - see this
        // screen's own initState comment) tears down and rebuilds the
        // timeline ListView below once loading finishes, which resets its
        // ScrollController back to offset 0 (a brand new Scrollable
        // attaching to this controller has no memory of the old one's
        // position - only initialScrollOffset, which defaults to 0). Reset
        // this here (a plain field, not Rx - no setState needed, this
        // build pass doesn't read it) so the post-loading rebuild re-arms
        // the auto-scroll-to-now instead of silently leaving the freshly
        // reset ListView sitting at the top.
        _hasAutoScrolledToCurrent = false;
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
    final timeline = _buildTimelineBody();

    // Embedded inside DietAndExerciseScreen - that parent already owns one
    // single Scaffold/AppBar/day-strip/bottom-buttons shared with the
    // Exercises pill, so this screen contributes just its meal timeline,
    // nothing else.
    if (widget.embedded) return timeline;

    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      // Only reachable via Routes.DIET_PLAN's standalone (currently
      // unlinked) deep-link entry point - the bottom nav always goes
      // through DietAndExerciseScreen (embedded: true) instead.
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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(DietWeekRow.height),
          child: DietWeekRow(),
        ),
      ),

      body: timeline,
      bottomNavigationBar: const DietBottomActions(),
    );
  }

  // ---------------- VERTICAL MEAL TIMELINE ----------------
  // One scrollable column, Morning Drink through Night Drink in order,
  // each with a status dot (logged/missed/upcoming - see
  // _MealTimelineSection) instead of the old 7-tab TabBar+TabBarView -
  // no per-tab switching needed to see the whole day at a glance, same
  // as Goal Journey's own vertical task list.
  Widget _buildTimelineBody() {
    return Obx(() {
      // Read here so the whole timeline rebuilds when the day changes
      // and when logMealData's fetch for it actually lands - logMealData
      // itself is a plain (non-Rx) field (see DietController), so
      // showLogMealLoading flipping false->true->false around its
      // assignment in getLogMeal is what this Obx actually needs to
      // react to; selectedDate.value alone would only catch the
      // synchronous day-switch, not the async fetch completing after it.
      final _ = [
        controller.selectedDate.value,
        controller.showLogMealLoading.value,
      ];
      final currentServing = controller.currentServingTimeNow;

      // Scroll to "now" once real content is on screen, animated - not
      // an instant jump, so it reads as the screen bringing the current
      // slot into view rather than just starting there.
      if (!_hasAutoScrolledToCurrent && currentServing != null) {
        _hasAutoScrolledToCurrent = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final sectionContext = _sectionKeys[currentServing]?.currentContext;
          if (sectionContext != null) {
            Scrollable.ensureVisible(
              sectionContext,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              // alignment: 0.0, not 0.15 - a serving section (label +
              // however many recipe cards) is routinely taller than the
              // viewport, and ensureVisible's alignment positions the
              // target's leading edge at that fraction of the viewport
              // regardless of whether the whole target fits. 0.15 pushed
              // the label itself above the visible area, leaving only a
              // mid-section recipe card showing at the top. 0.0 pins the
              // section's top (the label/dot) to the viewport's top edge
              // no matter how tall the section is.
              alignment: 0.0,
            );
          }
        });
      }

      return ListView(
        controller: _scrollController,
        // A plain ListView(children:) still lazily builds its SliverList
        // children by viewport + cacheExtent, not all-at-once just
        // because the widget list itself was built eagerly - the default
        // cacheExtent (~250px) routinely isn't enough to reach Lunch (the
        // 4th of 7 sections) once a couple of sections have recipe cards
        // in them, so its GlobalKey.currentContext is still null when the
        // auto-scroll-to-now and focusTabRequest jumps below run,
        // and Scrollable.ensureVisible silently does nothing. A single
        // day's timeline is inherently bounded (7 serving times +
        // Supplements, a handful of recipes each), so forcing the whole
        // thing to build up front is cheap and guarantees every section's
        // context exists by the time either jump fires.
        scrollCacheExtent: const ScrollCacheExtent.pixels(5000),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (final servingTime in _servingOrder)
            _MealTimelineSection(
              key: _sectionKeys[servingTime],
              servingTime: servingTime,
              displayLabel: servingTime == 'Evening Snack'
                  ? 'Evening Snacks'
                  : servingTime,
              isLast: false,
              isLogged: controller.isServingTimeLogged(servingTime),
              isPast: controller.isServingTimePast(servingTime),
              isBlinking: servingTime == currentServing,
              child: _buildFoodColumn(
                controller.getRecipesForServing(servingTime),
                servingTime: servingTime,
              ),
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
            child: _buildSupplementsColumn(
              controller.getSupplementRecipes(),
              controller.getTimedSupplements(),
            ),
          ),
        ],
      );
    });
  }

  // ------------------- BUILD FOOD COLUMN -------------------
  // Plain Column, not its own ListView - the whole day's timeline scrolls
  // as one list now (see build's body), so each section just contributes
  // its cards inline instead of owning a separate scroll region.
  // [servingTime] is only passed for a real meal slot (Morning Drink..Night
  // Drink), never for the Supplements section (see _buildSupplementsColumn)
  // - when present, each card gets a QuickLogButton (see quick_log_button.dart).
  Widget _buildFoodColumn(List<Recipe> recipes, {String? servingTime}) {
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
            trailing: servingTime != null
                ? QuickLogButton(servingTime: servingTime, recipeId: recipe.id)
                : null,
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

  // ------------- BUILD SUPPLEMENTS COLUMN -------------
  // Two additive sources shown together: recipe-tag-based supplements
  // (the existing mechanism - a plain recipe selection whose category
  // happens to be 'Supplements') and timing-anchored ones injected via the
  // dietician wizard's Timeline Builder (real dosage/instructions/timing,
  // see DietController.getTimedSupplements). Only falls back to the empty
  // state when BOTH are empty, so a plan with only wizard-injected
  // supplements doesn't show a misleading "No recipes" message above them.
  Widget _buildSupplementsColumn(
    List<Recipe> taggedRecipes,
    List<TimedSupplementDisplay> timedSupplements,
  ) {
    if (taggedRecipes.isEmpty && timedSupplements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: AppEmptyState(
          message: 'No recipes for this meal yet.',
          icon: Icons.restaurant_menu_outlined,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (taggedRecipes.isNotEmpty) _buildFoodColumn(taggedRecipes),
        for (final timed in timedSupplements)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: CustomText(
                    text: timed.entry.timingLabel,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff851653),
                  ),
                ),
                if (timed.recipe != null)
                  FoodCard(
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
                              return RecipeDetailsScreen(
                                scrollController: scrollController,
                                recipe: timed.recipe!,
                              );
                            },
                          );
                        },
                      );
                    },
                    image: timed.recipe!.image,
                    name: timed.recipe!.name,
                    gram: timed.recipe!.servingSize.quantity.round().toString(),
                    unit: timed.recipe!.servingSize.unit,
                    components: timed.recipe!.components,
                    calorie: timed.recipe!.nutritionPerServing.calories
                        .round()
                        .toString(),
                    protein: timed.recipe!.nutritionPerServing.protein
                        .round()
                        .toString(),
                    carbs: timed.recipe!.nutritionPerServing.carbs
                        .round()
                        .toString(),
                    fat: timed.recipe!.nutritionPerServing.fats
                        .round()
                        .toString(),
                    fiber: timed.recipe!.nutritionPerServing.fiber
                        .round()
                        .toString(),
                    supplementNutrientLabels: timed
                        .recipe!
                        .supplementFacts
                        ?.nutrients
                        .map((n) => n.displayLabel)
                        .toList(),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomText(
                      text:
                          timed.displayName +
                          (timed.entry.dosage != null
                              ? ' · ${timed.entry.dosage}'
                              : ''),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff384250),
                    ),
                  ),
                if (timed.entry.instructions != null &&
                    timed.entry.instructions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2),
                    child: CustomText(
                      text: timed.entry.instructions!,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xff6C737F),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
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
        border: (done || missed)
            ? null
            : Border.all(color: _upcomingBorder, width: 2),
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
