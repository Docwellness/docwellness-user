import 'package:docwellness/app/modules/diet/views/diet_view.dart';
import 'package:docwellness/app/modules/exercise/views/exercise_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Combines the Diet Plan and Exercise Plan screens under one bottom-nav
/// tab, mirroring docwellness-dietician's DietAndExerciseView: a pill
/// switcher (Diet Plan | Exercises) embedded into whichever inner screen's
/// own AppBar is currently showing (see DietPlanScreen/ExerciseView's
/// headerSwitcher param), rather than stacking a second header bar above
/// both - each inner screen keeps its own already-complex AppBar/body/
/// bottomNavigationBar completely untouched. Each mode is built once on
/// first visit and then kept alive (an IndexedStack, not a TabBarView) so
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
  late final TabController _tabController = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _mode = _tabController.index);
      }
    });

  int _mode = 0;
  final List<Widget?> _modes = List<Widget?>.filled(2, null);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _modeAt(int index, Widget switcher) {
    return _modes[index] ??= switch (index) {
      0 => DietPlanScreen(headerSwitcher: switcher),
      1 => ExerciseView(headerSwitcher: switcher),
      _ => DietPlanScreen(headerSwitcher: switcher),
    };
  }

  @override
  Widget build(BuildContext context) {
    final switcher = _PillSwitcher(controller: _tabController);
    return IndexedStack(
      index: _mode,
      children: List.generate(2, (index) {
        if (index != _mode && _modes[index] == null) {
          return const SizedBox.shrink();
        }
        return _modeAt(index, switcher);
      }),
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
          indicator: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(22)),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          splashBorderRadius: BorderRadius.circular(22),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xff384250),
          labelStyle: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(height: 44, iconMargin: EdgeInsets.zero, child: _SwitcherLabel(icon: Icons.restaurant_menu_rounded, text: 'Diet Plan')),
            Tab(height: 44, iconMargin: EdgeInsets.zero, child: _SwitcherLabel(icon: Icons.fitness_center_rounded, text: 'Exercises')),
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
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
