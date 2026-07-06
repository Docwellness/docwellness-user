/// Centralized app configuration
/// Change the base URL here and it applies everywhere
class AppConfig {
  AppConfig._();

  /// Base server URL (no trailing slash)
  /// For Android Emulator use: http://10.0.2.2:3000 (or http://localhost:3000 with adb reverse)
  /// For iOS Simulator use:    http://localhost:3000
  /// For real device use:      http://<your-ip>:3000
  /// For production use:       https://your-api-domain.com
  static const String baseUrl = 'http://65.20.81.44:5001';

  /// API base URL (baseUrl + /api)
  static const String apiBaseUrl = '$baseUrl/api';

  /// Patient API base URL
  static const String patientApiBaseUrl = '$apiBaseUrl/patient';
}
