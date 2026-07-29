import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/modules/auth/services/auth_service.dart';
import 'core/config/env_service.dart';
import 'core/session/session_service.dart';
import 'utils/app_theme/app_date_picker_theme.dart';
import 'app/models/message_model.dart';
import 'app/modules/diet/controllers/diet_controller.dart';
import 'app/modules/home/controllers/quotes_controller.dart';
import 'app/modules/home/controllers/videos_controller.dart';
import 'app/modules/home/controllers/water_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/services/connectivity_service.dart';
import 'app/services/push_notification_service.dart';
import 'app/services/recipe_language_service.dart';
import 'app/services/socket_service.dart';

/// Thin bridge over SessionService (see core/session/session_service.dart)
/// so the ~30 existing call sites that read/write these globals directly
/// keep working unchanged, while the actual session data now lives in the
/// service's secure-storage-backed state instead of a bare in-memory
/// global that's lost on every app restart. SessionService must already be
/// registered (see _bootstrap's first line) before anything touches these.
String? get userId => SessionService.to.userId;
set userId(String? value) => unawaited(SessionService.to.setUserId(value));

String? get token => SessionService.to.token;
set token(String? value) => unawaited(SessionService.to.setToken(value));

String? get role => SessionService.to.userRole;
set role(String? value) => unawaited(SessionService.to.setUserRole(value));

// False until runApp() has actually been called - guards
// ApiService._handleUnauthorized() against reacting to a 401 that occurs
// during _bootstrap() (e.g. from getUserData()'s own /auth/me call): there's
// no navigator to redirect to yet at that point, and getUserData() already
// has its own, more precise handling for that exact case.
bool appStarted = false;

// Dev-only shortcut to skip the real login flow and act as a specific
// patient - inert unless a developer explicitly supplies all three via
// --dart-define for a local debugging session (see AI_EXECUTION_PLAN.md
// Phase 1, P1-01: no real-looking token/patient id may sit in source).
const bool testMode = String.fromEnvironment('TEST_MODE') == 'true';
const String testPatientId = String.fromEnvironment('TEST_PATIENT_ID');
const String testPatientToken = String.fromEnvironment('TEST_PATIENT_TOKEN');

void main() async {
  // WidgetsFlutterBinding.ensureInitialized() must be called for the first
  // time in the same zone runApp() ends up running in - SentryFlutter.init's
  // appRunner runs inside its own runZonedGuarded zone, so calling
  // ensureInitialized() here in main()'s outer zone (when Sentry is enabled)
  // caused a "Zone mismatch" assertion. Both branches now call it from
  // inside _bootstrap(), invoked directly in main()'s zone when Sentry is
  // off, or inside appRunner's zone when it's on.
  if (EnvService.sentryDsn.isEmpty) {
    await _bootstrap();
    runApp(MyApp());
    appStarted = true;
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = EnvService.sentryDsn;
        options.environment = EnvService.appEnv;
        options.tracesSampleRate = 0.0;
        // Supabase's background token-refresh timer throws this whenever the
        // device has no network (DNS lookup failure mid-refresh) - it's
        // already retried internally by gotrue and recovered by
        // getUserData()'s cached-value fallback + ConnectivityService's
        // reconnect callback, so it's expected offline behavior, not an
        // actionable bug. Drop it instead of paging on every user who opens
        // the app on a bad connection.
        options.beforeSend = (event, hint) {
          if (event.throwable is AuthRetryableFetchException) return null;
          return event;
        };
      },
      appRunner: () async {
        await _bootstrap();
        runApp(MyApp());
        appStarted = true;
      },
    );
  }
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registered before anything else - the userId/token/role getters and
  // setters above delegate to this immediately, including from inside
  // getUserData() further down this same function.
  await Get.putAsync(() => SessionService().init(), permanent: true);

  // Not awaited - a stale default for the first frame or two is harmless
  // (RecipeDetailsScreen/Settings just show 'English' briefly before the
  // stored preference, if any, loads in), not worth delaying bootstrap for.
  unawaited(RecipeLanguageService.instance.load());

  await Get.putAsync(() => ConnectivityService().init(), permanent: true);

  if (EnvService.supabaseUrl.isNotEmpty) {
    await Supabase.initialize(
      url: EnvService.supabaseUrl,
      publishableKey: EnvService.supabasePublishableKey,
    );

    // Auth/login/signUp set `token` at the moment they get a session, but
    // Supabase silently refreshes tokens in the background over a long app
    // session - this keeps the global in sync with those refreshes too, so
    // the ~30 files that read `token` directly never see a stale value.
    Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      token = state.session?.accessToken;
    });
  }

  await getUserData();

  // Firebase push (Goal Journey Timeline nudges). Wrapped defensively:
  // without google-services.json configured for this build, initialization
  // throws - that must never crash the rest of app bootstrap, matching the
  // backend's utils/push.js "optional integration degrades gracefully"
  // convention. PushNotificationService.init() itself (which needs an
  // authenticated user to register a device token) is called further down,
  // only once userId is known.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase.initializeApp() failed (non-fatal, push disabled): $e');
  }

  // Suppress raw Flutter framework errors — never show red crash screens
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: false);
    if (EnvService.sentryDsn.isNotEmpty) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }
  };
  // Replace red error widget with blank box so nothing leaks to user
  ErrorWidget.builder = (_) => const SizedBox.shrink();

  // For testing: override with test credentials
  if (testMode && testPatientId.isNotEmpty && testPatientToken.isNotEmpty) {
    userId = testPatientId;
    token = testPatientToken;
    role = 'patient';
    debugPrint('🧪 TEST MODE: userId=$userId');
  }

  // Initialize socket service if user is logged in
  if (userId != null && userId!.isNotEmpty) {
    Get.put(SocketService());
    Get.lazyPut<DietController>(() => DietController(), fenix: true);
    // Permanent WaterController so 11 PM auto-sync timer survives navigation
    Get.put<WaterController>(WaterController(), permanent: true);
    // Permanent so HomeController.refreshAllData() can always find them to
    // trigger a re-fetch on pull-to-refresh, regardless of whether
    // VideosSection/QuotesSection have been built yet this session.
    Get.put<VideosController>(VideosController(), permanent: true);
    Get.put<QuotesController>(QuotesController(), permanent: true);
    MessageModel.setCurrentUserId(userId!);
    unawaited(PushNotificationService().init());
  }

  await _initPostHog();
}

Future<void> _initPostHog() async {
  if (EnvService.posthogApiKey.isEmpty) return;
  final config = PostHogConfig(EnvService.posthogApiKey)
    ..host = EnvService.posthogHost
    ..captureApplicationLifecycleEvents = true
    ..sessionReplay = true
    ..debug = EnvService.appEnv == 'development';
  config.errorTrackingConfig.captureFlutterErrors = true;
  config.errorTrackingConfig.capturePlatformDispatcherErrors = true;
  await Posthog().setup(config);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Application",
      navigatorObservers: [PosthogObserver()],
      // Always starts at the splash screen now - it makes the same
      // AUTH-vs-HOME choice this ternary used to make directly (see
      // SplashView) after its brief display delay.
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff851653),
          primary: const Color(0xff851653),
          onPrimary: Colors.white,
          surface: const Color(0xffFEF6FB),
        ),
        datePickerTheme: brandDatePickerTheme,
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xffFEF6FB),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1F2A37),
          ),
          contentTextStyle: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xff4D5761),
            height: 1.4,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xff530630)),
        ),
      ),
      // Reserves space for the system's bottom navigation (3-button bar or
      // gesture-nav inset) on every single screen, not just ones with a
      // Scaffold.bottomNavigationBar - apps targeting Android 15+ render
      // edge-to-edge by default, so anything ending near the bottom of a
      // plain scrollable body (e.g. a form's submit button) was otherwise
      // getting drawn underneath the system nav bar. top: false since each
      // screen's own AppBar already accounts for the status bar correctly.
      builder: (context, child) =>
          SafeArea(top: false, child: child ?? const SizedBox.shrink()),
      onInit: () {
        // Connect socket after app initializes (deferred to avoid blocking startup)
        if (userId != null && userId!.isNotEmpty) {
          Future.delayed(const Duration(seconds: 1), () {
            try {
              final socketService = Get.find<SocketService>();
              socketService.init();
            } catch (e) {
              log('Socket service not initialized: $e');
            }
          });
        }
      },
    );
  }
}

/// Populates the userId/token/role globals from the current Supabase
/// session (if any). Mongo's `_id`/`role` aren't part of the Supabase
/// session itself, so this makes one call to /auth/me to fetch them -
/// falling back to the last-cached values if that fails (e.g. offline)
/// rather than forcing a logout.
Future<void> getUserData() async {
  final SharedPreferences pref = await SharedPreferences.getInstance();

  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    await pref.clear();
    await SessionService.to.clear();
    return;
  }

  // Proactively refresh a token that's already expired (or about to) before
  // this app's own bootstrap call ever uses it - Supabase access tokens are
  // short-lived (1h JWT), and relying on the SDK's background auto-refresh
  // timer to have already fired by this exact instant (right at cold start)
  // was a race: a stale token here produced a 401 from /auth/me, which used
  // to be misread as "no profile exists yet" and wrongly routed a fully
  // registered user into the onboarding resume flow (see the isNoProfile
  // check below - this is exactly the case it must not trigger for).
  final expiresAt = session.expiresAt;
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final needsRefresh = expiresAt == null || nowSeconds >= expiresAt - 30;

  if (needsRefresh) {
    try {
      final refreshed = await Supabase.instance.client.auth.refreshSession();
      token = refreshed.session?.accessToken ?? session.accessToken;
    } on AuthRetryableFetchException catch (e) {
      // A network/connectivity failure (DNS lookup, socket error, timeout)
      // reaching Supabase - says nothing about whether the refresh token
      // itself is valid. Matches this function's own doc comment: fall
      // back to the last-known access token and let the app continue
      // (offline) rather than forcing a logout, which is what the
      // catch-all branch below used to do for this case too (confirmed in
      // production error tracking - a transient DNS blip during cold start
      // was wrongly clearing a perfectly valid session).
      debugPrint('getUserData: refreshSession hit a network error, using cached token: $e');
      token = session.accessToken;
    } catch (e) {
      // Any other failure here means the refresh token itself is dead
      // (expired/revoked) - a genuine "please log in again" case. Clear
      // everything so SplashView routes to AUTH instead of resuming
      // onboarding or reusing a session that no longer exists.
      debugPrint('getUserData: refreshSession failed, treating as logged out: $e');
      await pref.clear();
      await SessionService.to.clear();
      return;
    }
  } else {
    token = session.accessToken;
  }

  final result = await AuthService().getUserInfo(token!);
  if (result.isSuccess) {
    // Persisted automatically via the setter bridge -> SessionService's
    // secure storage, so this is now the one place these values are
    // cached (no separate SharedPreferences copy - see the fallback
    // branch below).
    userId = result.data!['data']['_id'];
    role = result.data!['data']['role'];
  } else if (result.isNoProfile) {
    // Session exists (email verified) but no linked Mongo profile yet -
    // signup was interrupted before the rest of onboarding + final
    // registration completed. `token` is deliberately kept (not treated
    // as fully logged out) so SplashView can resume straight into
    // PersonalInfoView instead of sending them back to the welcome
    // screen - see SplashView.
    userId = null;
    role = null;
  } else {
    // 401/network/anything else - says nothing about whether a profile
    // exists, so don't touch userId/role: the getters already return
    // whatever was last securely persisted (this session's earlier
    // success, or last session's value hydrated at boot by
    // SessionService.init()) - explicitly reassigning here would just
    // write the same value back. Falls back to that cached profile
    // instead of forcing a logout or onboarding resume over what's likely
    // a transient hiccup.
    debugPrint(
      'getUserData: /auth/me returned ${result.statusCode}, using cached profile',
    );
  }

  debugPrint('----------------userId: $userId');
  log('--------$token');
}
