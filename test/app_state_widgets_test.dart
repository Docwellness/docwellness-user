// AI_EXECUTION_PLAN.md Phase 8, P8-02 - home dashboard loading/error/empty
// and diet plan loading/error/empty. These states are provided by the
// shared widgets added in Phase 6 (lib/shared/widgets/) - AppLoader/
// AppErrorState/AppEmptyState aren't yet wired into the Home/Diet screens
// themselves (each still hand-rolls its own inline loading/empty checks),
// so this tests the shared components directly rather than claiming
// end-to-end screen coverage that doesn't exist yet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellness/shared/widgets/app_loader.dart';
import 'package:docwellness/shared/widgets/app_error_state.dart';
import 'package:docwellness/shared/widgets/app_empty_state.dart';

void main() {
  testWidgets('AppLoader shows a progress indicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppLoader()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('AppErrorState', () {
    testWidgets('shows the message and no retry button when onRetry is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppErrorState(message: 'Could not load data'),
        ),
      );
      expect(find.text('Could not load data'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('tapping Retry calls onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AppErrorState(
            message: 'Could not load data',
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  testWidgets('AppEmptyState shows its message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppEmptyState(message: 'No meals logged yet')),
    );
    expect(find.text('No meals logged yet'), findsOneWidget);
  });
}
