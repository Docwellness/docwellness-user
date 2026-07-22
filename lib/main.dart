import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/config/app_config.dart';
import 'app/modules/auth/services/auth_service.dart';
import 'utils/app_theme/app_date_picker_theme.dart';
import 'app/models/message_model.dart';
import 'app/modules/diet/controllers/diet_controller.dart';
import 'app/modules/home/controllers/water_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/services/connectivity_service.dart';
import 'app/services/socket_service.dart';

String? userId;
String? token;
String? role;

const bool testMode = false;
const String testPatientId = '698097813b0d03d888c0ce52';
const String testPatientToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5ODA5NzgxM2IwZDAzZDg4OGMwY2U1MiIsImlhdCI6MTc3MTA2MDExMywiZXhwIjoxNzczNjUyMTEzfQ.bXaAJokFGfT4NT16r-javnQCXbyG3jIKP9n8ifJ3pEM';

// Sentry/PostHog are only enabled once a real DSN/API key is supplied via
// --dart-define at build time; empty defaults keep both no-ops so local runs
// without those defines behave exactly as before.
const String _sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: '',
);
const String _appEnv = String.fromEnvironment(
  'ENV',
  defaultValue: 'development',
);
const String _posthogApiKey = String.fromEnvironment(
  'POSTHOG_API_KEY',
  defaultValue: '',
);
const String _posthogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);

void main() async {
  // WidgetsFlutterBinding.ensureInitialized() must be called for the first
  // time in the same zone runApp() ends up running in - SentryFlutter.init's
  // appRunner runs inside its own runZonedGuarded zone, so calling
  // ensureInitialized() here in main()'s outer zone (when Sentry is enabled)
  // caused a "Zone mismatch" assertion. Both branches now call it from
  // inside _bootstrap(), invoked directly in main()'s zone when Sentry is
  // off, or inside appRunner's zone when it's on.
  if (_sentryDsn.isEmpty) {
    await _bootstrap();
    runApp(MyApp());
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.environment = _appEnv;
        options.tracesSampleRate = 0.0;
      },
      appRunner: () async {
        await _bootstrap();
        runApp(MyApp());
      },
    );
  }
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Get.putAsync(() => ConnectivityService().init(), permanent: true);

  if (AppConfig.supabaseUrl.isNotEmpty) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
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

  // Suppress raw Flutter framework errors — never show red crash screens
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: false);
    if (_sentryDsn.isNotEmpty)
      Sentry.captureException(details.exception, stackTrace: details.stack);
  };
  // Replace red error widget with blank box so nothing leaks to user
  ErrorWidget.builder = (_) => const SizedBox.shrink();

  // For testing: override with test credentials
  if (testMode) {
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
    MessageModel.setCurrentUserId(userId!);
  }

  await _initPostHog();
}

Future<void> _initPostHog() async {
  if (_posthogApiKey.isEmpty) return;
  final config = PostHogConfig(_posthogApiKey)
    ..host = _posthogHost
    ..captureApplicationLifecycleEvents = true
    ..sessionReplay = true
    ..debug = _appEnv == 'development';
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
    return;
  }

  token = session.accessToken;

  try {
    final response = await AuthService().getUserInfo(token!);
    if (response != null && response['data'] != null) {
      userId = response['data']['_id'];
      role = response['data']['role'];
      await pref.setString('userId', userId!);
      await pref.setString('role', role!);
    } else {
      // Session exists (email verified) but no linked Mongo profile yet -
      // signup was interrupted before the rest of onboarding + final
      // registration completed. `token` is deliberately kept (not treated
      // as fully logged out) so SplashView can resume straight into
      // PersonalInfoView instead of sending them back to the welcome
      // screen - see SplashView.
      userId = null;
      role = null;
    }
  } catch (e) {
    // Network failure - fall back to cached values instead of forcing a
    // logout, so the app still opens offline with last-known state.
    userId = pref.getString('userId');
    role = pref.getString('role');
    debugPrint('getUserData: /auth/me failed, using cached profile: $e');
  }

  debugPrint('----------------userId: $userId');
  log('--------$token');
}
