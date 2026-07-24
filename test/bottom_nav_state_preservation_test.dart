// AI_EXECUTION_PLAN.md Phase 8, P8-02 - bottom navigation state
// preservation.
//
// bottom_navi_bar.dart's real BottomNaviBar depends on
// Get.find<HomeController>() (network services, GetX bindings, etc.),
// which isn't practical or desirable to stand up in a widget test. This
// exercises the exact lazy-build-then-IndexedStack mechanism it uses
// (see bottom_navi_bar.dart's _screenAt/_screens) in an isolated harness:
// a tab's widget is only constructed the first time it's selected, and -
// this is the actual behavior being verified - switching away and back
// preserves that widget's State (a counter here) instead of resetting it,
// which is exactly the bug IndexedStack replaced (each tab switch used to
// rebuild a fresh widget subtree from scratch).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterTab extends StatefulWidget {
  final int index;
  final VoidCallback onBuilt;
  const _CounterTab({required this.index, required this.onBuilt});

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    widget.onBuilt();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Tab ${widget.index}: $count'),
        TextButton(
          onPressed: () => setState(() => count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class _LazyIndexedStackNav extends StatefulWidget {
  const _LazyIndexedStackNav();

  @override
  State<_LazyIndexedStackNav> createState() => _LazyIndexedStackNavState();
}

class _LazyIndexedStackNavState extends State<_LazyIndexedStackNav> {
  int selectedIndex = 0;
  final List<Widget?> _screens = List<Widget?>.filled(3, null);
  final Set<int> builtIndices = {};

  Widget _screenAt(int index) {
    return _screens[index] ??= _CounterTab(
      index: index,
      onBuilt: () => builtIndices.add(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: List.generate(_screens.length, (index) {
          if (index != selectedIndex && _screens[index] == null) {
            return const SizedBox.shrink();
          }
          return _screenAt(index);
        }),
      ),
      bottomNavigationBar: Row(
        children: List.generate(
          3,
          (index) => TextButton(
            onPressed: () => setState(() => selectedIndex = index),
            child: Text('Tab $index'),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'switching tabs preserves each tab\'s state instead of rebuilding it',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _LazyIndexedStackNav()),
      );

      // Only the initially-selected tab (0) is built - matches
      // bottom_navi_bar.dart never eagerly building unvisited tabs.
      final state = tester.state<_LazyIndexedStackNavState>(
        find.byType(_LazyIndexedStackNav),
      );
      expect(state.builtIndices, {0});

      // Increment tab 0's counter.
      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('Tab 0: 1'), findsOneWidget);

      // Switch to tab 1 - lazily builds it for the first time.
      await tester.tap(find.text('Tab 1'));
      await tester.pump();
      expect(state.builtIndices, {0, 1});
      expect(find.text('Tab 1: 0'), findsOneWidget);

      // Switch back to tab 0 - its counter must still read 1, not have
      // been reset by a rebuild.
      await tester.tap(find.text('Tab 0'));
      await tester.pump();
      expect(find.text('Tab 0: 1'), findsOneWidget);

      // Tab 2 was never visited, so it was never built.
      expect(state.builtIndices, {0, 1});
    },
  );
}
