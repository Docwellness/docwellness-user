import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/app/modules/diet/views/diet_view.dart';
import 'package:docwellness/app/modules/exercise/controllers/exercise_controller.dart';
import 'package:docwellness/app/modules/exercise/views/exercise_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Combines the Diet Plan and Exercise Plan screens under one bottom-nav
/// tab, mirroring docwellness-dietician's DietAndExerciseView: a pill
/// switcher (Diet Plan | Exercises), ONE shared AppBar+day strip (see
/// DietWeekRow) and ONE shared "Log Meal"/"Report Allergies" bottom bar
/// (shown only for the Diet Plan pill) that this screen itself owns,
/// instead of each pill dragging along its own separate copy of all three
/// - two independently-built widgets that merely looked the same is what
/// let them visually drift apart (different pink-header heights, etc. -
/// see DietWeekRow/DietBottomActions' own doc comments) and meant tapping a
/// day only updated whichever controller that pill's own strip happened to
/// be wired to. DietPlanScreen/ExerciseView (both embedded: true here) now
/// contribute only their own body content. Each mode is built once on first
/// visit and then kept alive (an IndexedStack, not a TabBarView) so
/// switching back to Exercises after browsing Diet doesn't lose scroll
/// position or re-fetch - the same lazy-then-keep-alive pattern
/// bottom_navi_bar.dart uses for its own 5 tabs.
class DietAndExerciseScreen extends StatefulWidget {
  const DietAndExerciseScreen({super.key});

  @override
  State<DietAndExerciseScreen> createState() => _DietAndExerciseScreenState();
}

class _DietAndExerciseScreenState extends State<DietAndExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this)..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _mode = _tabController.index);
        }
      });

  int _mode = 0;
  final List<Widget?> _modes = List<Widget?>.filled(2, null);
  Worker? _focusModeWorker;

  late final DietController _dietController;
  late final ExerciseController _exerciseController;

  @override
  void initState() {
    super.initState();
    // Eagerly ensure BOTH controllers are registered (and therefore both
    // fetching) the moment this combined screen first builds - i.e. the
    // moment the bottom nav's Diet & Exercise tab is first selected, not
    // lazily per-pill. DietController is already a permanent app-wide
    // singleton loaded at login by this point in practice, but
    // ExerciseController previously was only ever instantiated (kicking off
    // its own fetch) inside ExerciseView.build() - meaning the Exercises
    // pill's data didn't even start loading until the patient tapped that
    // pill specifically, showing a loading spinner on that first tap even
    // though Diet Plan (already loaded) was instant. Both are now permanent
    // for the same reason DietController already was: this combined screen
    // (and both controllers' data) should stay alive for the whole app
    // session once first visited, same as every other bottom nav tab.
    _dietController = Get.isRegistered<DietController>()
        ? Get.find<DietController>()
        : Get.put(DietController(), permanent: true);
    _exerciseController = Get.isRegistered<ExerciseController>()
        ? Get.find<ExerciseController>()
        : Get.put(ExerciseController(), permanent: true);

    // See DietController.focusModeRequest's doc comment - answers a
    // request to open directly on the Exercises pill (e.g. Home's "Log
    // Exercise" button) from outside, which has no direct handle on this
    // screen's TabController.
    _focusModeWorker = ever<int>(_dietController.focusModeRequest, (index) {
      if (index < 0 || index >= 2) return;
      _tabController.animateTo(index);
      setState(() => _mode = index);
      _dietController.focusModeRequest.value = -1;
    });
    // A request set before this screen ever built (e.g. tapping "Log
    // Exercise" the very first time, before DietAndExerciseScreen has
    // been visited yet at all) has already fired and been missed by the
    // `ever` worker above, which only reacts to *future* changes -
    // consume it directly here too. Sets the TabController's index
    // directly (not animateTo) since there's no prior frame to animate
    // from yet.
    final pending = _dietController.focusModeRequest.value;
    if (pending >= 0 && pending < 2) {
      _mode = pending;
      _tabController.index = pending;
      _dietController.focusModeRequest.value = -1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusModeWorker?.dispose();
    super.dispose();
  }

  Widget _modeAt(int index) {
    return _modes[index] ??= switch (index) {
      0 => const DietPlanScreen(embedded: true),
      1 => const ExerciseView(embedded: true),
      _ => const DietPlanScreen(embedded: true),
    };
  }

  // The single day strip's tap handler - updates BOTH controllers together
  // (there's only one strip now, shared by both pills) so whichever pill
  // the patient switches to next already reflects the day they just
  // picked, instead of only the pill that happened to own that strip
  // instance before this screen unified the two.
  void _onDaySelected(DateTime date) {
    _dietController.switchDate(date);
    _exerciseController.switchDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        // A primary bottom-nav destination - never a back arrow, even when
        // it was reached via a deep link / focusModeRequest that left a
        // poppable route underneath (the bottom nav is the way back).
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: _PillSwitcher(controller: _tabController),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(DietWeekRow.height),
          child: DietWeekRow(onDaySelected: _onDaySelected),
        ),
      ),
      body: IndexedStack(
        index: _mode,
        children: List.generate(2, (index) {
          if (index != _mode && _modes[index] == null) {
            return const SizedBox.shrink();
          }
          return _modeAt(index);
        }),
      ),
      // Log Meal/Report Allergies only make sense for the Diet Plan pill -
      // Exercises logs per-exercise inline instead (see _ExerciseTile's own
      // Log/Edit buttons), no shared bottom action bar of its own.
      bottomNavigationBar: _mode == 0 ? const DietBottomActions() : null,
    );
  }
}

class _PillSwitcher extends StatelessWidget {
  final TabController controller;
  const _PillSwitcher({required this.controller});

  static const _accent = Color(0xff851653);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(22),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          splashBorderRadius: BorderRadius.circular(22),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xff384250),
          labelStyle: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(
              height: 44,
              iconMargin: EdgeInsets.zero,
              child: _SwitcherLabel(
                icon: Icons.restaurant_menu_rounded,
                text: 'Diet Plan',
              ),
            ),
            Tab(
              height: 44,
              iconMargin: EdgeInsets.zero,
              child: _SwitcherLabel(
                icon: Icons.fitness_center_rounded,
                text: 'Exercises',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deliberately plain Icon()/Text() with no explicit color/style so both
/// inherit the IconTheme/DefaultTextStyle the enclosing TabBar sets per tab
/// (selected vs unselected) - the same mechanism Tab's own built-in
/// icon/text params use internally.
class _SwitcherLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SwitcherLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(icon, size: 15), const SizedBox(width: 6), Text(text)],
    );
  }
}
