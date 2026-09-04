// ActivePlanActions is the Home action-button area for a patient with an
// active diet plan. It replaced the green "Subscription Active" banner:
// Log Meal / Log Exercise are always there for the current plan, and once
// the cycle is within kRenewalWindowDays of expiry the caller passes
// showRequestDietPlan and a "Request diet plan" button joins them so the
// patient can start their next plan before this one lapses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellness/app/modules/home/widgets/active_plan_actions.dart';

Widget _host({
  required bool dietEnabled,
  required bool showRequestDietPlan,
  VoidCallback? onLogMeal,
  VoidCallback? onLogExercise,
  VoidCallback? onRequestDietPlan,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ActivePlanActions(
        dietEnabled: dietEnabled,
        showRequestDietPlan: showRequestDietPlan,
        onLogMeal: onLogMeal ?? () {},
        onLogExercise: onLogExercise ?? () {},
        onRequestDietPlan: onRequestDietPlan ?? () {},
      ),
    ),
  );
}

void main() {
  testWidgets('more than 3 days out: only Log Meal / Log Exercise, and no '
      'leftover "Subscription Active" banner', (tester) async {
    await tester.pumpWidget(
      _host(dietEnabled: true, showRequestDietPlan: false),
    );

    expect(find.text('Log Meal'), findsOneWidget);
    expect(find.text('Log Exercise'), findsOneWidget);
    expect(find.text('Request diet plan'), findsNothing);
    // The green banner this widget replaced is gone for good.
    expect(find.textContaining('Subscription'), findsNothing);
    expect(find.textContaining('days remaining'), findsNothing);
  });

  testWidgets('within 3 days of expiry: Request diet plan joins the log '
      'buttons for the current plan', (tester) async {
    await tester.pumpWidget(
      _host(dietEnabled: true, showRequestDietPlan: true),
    );

    expect(find.text('Log Meal'), findsOneWidget);
    expect(find.text('Log Exercise'), findsOneWidget);
    expect(find.text('Request diet plan'), findsOneWidget);
  });

  testWidgets('each button invokes its callback', (tester) async {
    var meal = 0, exercise = 0, request = 0;
    await tester.pumpWidget(
      _host(
        dietEnabled: true,
        showRequestDietPlan: true,
        onLogMeal: () => meal++,
        onLogExercise: () => exercise++,
        onRequestDietPlan: () => request++,
      ),
    );

    await tester.tap(find.text('Log Meal'));
    await tester.tap(find.text('Log Exercise'));
    await tester.tap(find.text('Request diet plan'));
    await tester.pump();

    expect(meal, 1);
    expect(exercise, 1);
    expect(request, 1);
  });

  testWidgets('log buttons are inert until the diet plan starts '
      '(dietEnabled false), but Request diet plan still works', (tester) async {
    var meal = 0, request = 0;
    await tester.pumpWidget(
      _host(
        dietEnabled: false,
        showRequestDietPlan: true,
        onLogMeal: () => meal++,
        onRequestDietPlan: () => request++,
      ),
    );

    await tester.tap(find.text('Log Meal'));
    await tester.tap(find.text('Request diet plan'));
    await tester.pump();

    expect(meal, 0);
    expect(request, 1);
  });
}
