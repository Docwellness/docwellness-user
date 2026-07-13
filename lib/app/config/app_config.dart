/// Centralized app configuration
/// Change the base URL here and it applies everywhere
class AppConfig {
  AppConfig._();

  /// Base server URL (no trailing slash)
  /// For Android Emulator use: http://10.0.2.2:5000 (or http://localhost:5000 with adb reverse)
  /// For iOS Simulator/Web/Desktop use: http://localhost:5000
  /// For real device use:      http://<your-ip>:5000
  /// For production use:       https://your-api-domain.com
  static const String baseUrl = 'http://localhost:5000';

  /// API base URL (baseUrl + /api)
  static const String apiBaseUrl = '$baseUrl/api';

  /// Patient API base URL
  static const String patientApiBaseUrl = '$apiBaseUrl/patient';
}
