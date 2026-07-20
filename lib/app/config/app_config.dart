/// Centralized app configuration
/// Change the base URL here and it applies everywhere
class AppConfig {
  AppConfig._();

  /// Base server URL (no trailing slash). Override at build time with:
  ///   flutter build web --dart-define=API_BASE_URL=https://api-dev.example.com
  /// Defaults below are for local development:
  /// For Android Emulator use: http://10.0.2.2:5000 (or http://localhost:5000 with adb reverse)
  /// For iOS Simulator/Web/Desktop use: http://localhost:5000
  /// For real device use:      http://<your-ip>:5000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  /// API base URL (baseUrl + /api)
  static const String apiBaseUrl = '$baseUrl/api';

  /// Patient API base URL
  static const String patientApiBaseUrl = '$apiBaseUrl/patient';

  /// Supabase project URL and publishable (client-safe) key. Override with:
  ///   --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
}
