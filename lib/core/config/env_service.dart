/// Centralized compile-time environment configuration - every
/// --dart-define value this app reads lives here instead of scattered
/// String.fromEnvironment calls across main.dart and elsewhere. Fields are
/// static const (not instance/runtime state) because dart-define
/// substitution only happens at compile time - there is nothing to "load".
///
/// app/config/app_config.dart's AppConfig class predates this and is kept
/// as a backward-compatible facade over the API_BASE_URL/SUPABASE_* fields
/// here (11 existing files reference AppConfig.* directly) - new code
/// should read from EnvService directly instead.
class EnvService {
  EnvService._();

  /// Base server URL (no trailing slash, no path suffix - callers append
  /// their own /api/... path). Override at build time with:
  ///   flutter run --dart-define=API_BASE_URL=https://dev-api.docwellness.fit
  /// Defaults below are for local development:
  /// For Android Emulator use: http://10.0.2.2:5000 (or http://localhost:5000 with adb reverse)
  /// For iOS Simulator/Web/Desktop use: http://localhost:5000
  /// For real device use:      http://`your-ip`:5000
  static const String apiHost = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  /// Supabase project URL and publishable (client-safe) key. Override with:
  ///   --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  // Sentry/PostHog are only enabled once a real DSN/API key is supplied via
  // --dart-define at build time; empty defaults keep both no-ops so local
  // runs without those defines behave exactly as before.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  static const String appEnv = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );
  static const String posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );
}
