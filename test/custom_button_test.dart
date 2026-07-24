// AI_EXECUTION_PLAN.md Phase 8, P8-02 - login button state. CustomButton
// (lib/utils/common_widgets/custom_button.dart) is the shared button used
// on the login/auth screens (and everywhere else) - this covers its
// loading/disabled/enabled visual + interaction states directly.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';

void main() {
  testWidgets('shows the label and calls onTap when enabled', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Log In',
            isOutline: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Log In'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('shows a spinner instead of the label while loading, and '
      'onTap does not fire', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Log In',
            isOutline: false,
            isLoading: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Log In'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('disabled (enabled: false) does not call onTap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Log In',
            isOutline: false,
            enabled: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('meets the 48px minimum tap target and exposes a button '
      'semantics role (AI_EXECUTION_PLAN.md Phase 6, P6-09)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(text: 'Log In', isOutline: false, onTap: () {}),
        ),
      ),
    );

    final size = tester.getSize(find.byType(CustomButton));
    expect(size.height, greaterThanOrEqualTo(48));

    final semantics = tester.getSemantics(find.byType(CustomButton));
    // ignore: deprecated_member_use
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
  });
}
