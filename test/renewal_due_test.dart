// The rule behind Home's "Request diet plan" button: it appears once the
// current paid cycle is within kRenewalWindowDays (3) of expiry - or already
// past it - so the patient can line up their next plan before the current
// one lapses (see home_controller.dart's renewalDue / isRenewalDue and
// HomeView's Paid branch). renewalDue is a pure function with an injectable
// `now` precisely so this boundary can be pinned down without a real
// subscription approaching expiry.
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';

void main() {
  final now = DateTime(2026, 9, 4, 10, 0);
  DateTime inDays(double d) =>
      now.add(Duration(minutes: (d * 24 * 60).round()));

  group('renewalDue', () {
    test('the reminder window is 3 days, matching the backend sweep', () {
      expect(kRenewalWindowDays, 3);
    });

    test('false with no expiry date', () {
      expect(
        renewalDue(expiresAt: null, hasPaidCycle: true, now: now),
        isFalse,
      );
    });

    test('false when the request is not a paid cycle, even near expiry', () {
      expect(
        renewalDue(expiresAt: inDays(1), hasPaidCycle: false, now: now),
        isFalse,
      );
    });

    test('false while more than 3 days remain', () {
      expect(
        renewalDue(expiresAt: inDays(10), hasPaidCycle: true, now: now),
        isFalse,
      );
      expect(
        renewalDue(expiresAt: inDays(4.1), hasPaidCycle: true, now: now),
        isFalse,
      );
    });

    test('true from exactly 3 days out down to the wire', () {
      expect(
        renewalDue(expiresAt: inDays(3), hasPaidCycle: true, now: now),
        isTrue,
      );
      expect(
        renewalDue(expiresAt: inDays(2.5), hasPaidCycle: true, now: now),
        isTrue,
      );
      expect(
        renewalDue(expiresAt: inDays(0.5), hasPaidCycle: true, now: now),
        isTrue,
      );
    });

    test('stays true once the cycle has already expired', () {
      expect(
        renewalDue(expiresAt: inDays(-2), hasPaidCycle: true, now: now),
        isTrue,
      );
    });

    test('defaults `now` to DateTime.now() when not injected', () {
      expect(
        renewalDue(
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          hasPaidCycle: true,
        ),
        isTrue,
      );
      expect(
        renewalDue(
          expiresAt: DateTime.now().add(const Duration(days: 30)),
          hasPaidCycle: true,
        ),
        isFalse,
      );
    });
  });
}
