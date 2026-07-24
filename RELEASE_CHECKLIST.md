# Release Checklist — docwellness-user (Patient App)

Based on `docwellness-ai-plan/RELEASE_CHECKLIST.md` (AI_EXECUTION_PLAN.md
Phase 8, P8-05), filled in against the actual state of this repo as of the
`chore/senior-improvements-phase-0` branch (Phases 0-8). Re-verify anything
marked ⚠️ before deploying — this reflects what was true when last checked,
not a live status.

Legend: ✅ verified this session · ⚠️ needs action before release · ❔ not
verified (out of this session's scope)

---

## Security

- ✅ No hardcoded tokens - `lib/main.dart`'s hardcoded JWT literal removed, config sourced via `EnvService`/`--dart-define` (Phase 1)
- ✅ Secure storage used - `SessionService` backed by `flutter_secure_storage` (Phase 1)
- ✅ No secrets in logs - no token-printing debug statements found in this repo (unlike the dietician app, which had one - see that app's checklist)

## Patient App

- ✅ Login works, session persists securely, logout clears session (Phase 1)
- ✅ Home dashboard works
- ✅ Diet plan works - duplicate fetch removed, recipe cache added (Phase 6)
- ✅ Meal logging, water tracking, progress, chat, notifications, payment flow - pre-existing, not broken by this session's changes (verified via `flutter analyze` showing zero new errors after each phase)
- ⚠️ Error states / loading states / empty states - the reusable `AppLoader`/`AppErrorState`/`AppEmptyState` widgets exist (Phase 6) and are unit-tested (Phase 8), but are **not yet wired into the actual Home/Diet/other screens** - those screens still use their own inline loading/empty handling. Adopting the shared widgets screen-by-screen is follow-up work, not done in this session.
- ✅ Images cached - all 21 remaining raw `Image.network`/`NetworkImage` sites converted to `CachedNetworkImage`/`CachedNetworkImageProvider` (Phase 6)
- ✅ Chat pagination works - was already correctly implemented pre-session (verified, not modified)
- ✅ Chat deduplication - `clientMessageId`-based dedup added and closes a real race (sender's own message echoed back via socket before the REST response resolves) (Phase 6); unit-tested (Phase 8)
- ✅ Bottom navigation preserves state - lazy-built `IndexedStack` (Phase 6); the underlying mechanism is widget-tested (Phase 8) - the real `BottomNaviBar` itself isn't (it depends on `HomeController`'s full GetX/network wiring, impractical to stand up in a widget test)
- ✅ Accessibility improved - `CustomButton`/`QuickReplyButton` meet the 48px minimum tap target and expose `Semantics(button: true, ...)` (Phase 6)

## Monitoring

- ✅ Crash reporting enabled - `SentryFlutter.init`, DSN-gated (`EnvService.sentryDsn`), wraps `runApp` in `appRunner` so uncaught Flutter errors are captured automatically
- ✅ Analytics events enabled - PostHog already tracked `user_signed_up`/`user_logged_in`/`meal_logged`/`diet_plan_requested`/`payment_submitted`/`coupon_applied`/`water_intake_added`/`user_logged_out`/`confession_sent`/`body_data_logged`/`progress_shared`; Phase 8 added `login_success`, `dashboard_loaded`, `diet_plan_viewed`, `chat_message_sent`, `payment_started`, `payment_completed` (all additive - existing event names kept for backward compatibility with any dashboards built on them)
- ✅ No PHI in analytics - every new event was checked for this; e.g. `diet_plan_viewed` only sends the week number, `chat_message_sent` only sends `message_type`, `payment_*` events only send plan name/amount/coupon-applied (already the existing `payment_submitted` event's shape)
- ❔ `diet_plan_published` is dietician-app-only (the dietician is the one who publishes) - not applicable here

---

## Testing (this session, Phase 8)

`flutter test` - new tests added:
- `test/message_dedup_test.dart` - `MessageModel.isDuplicate` (extracted from `ChatController` as a pure function specifically to make this testable)
- `test/custom_button_test.dart` - login/CTA button loading/disabled/enabled states, 48px tap target, button semantics
- `test/app_state_widgets_test.dart` - `AppLoader`/`AppErrorState`/`AppEmptyState` (see the ⚠️ above - these aren't wired into real screens yet)
- `test/bottom_nav_state_preservation_test.dart` - the lazy-IndexedStack mechanism, in isolation (not the real `BottomNaviBar`, which needs a live `HomeController`)
- Pre-existing `test/widget_test.dart` ("Counter increments smoke test") still fails - unmodified `flutter create` boilerplate testing a counter widget that doesn't exist in this app, predates this session entirely
