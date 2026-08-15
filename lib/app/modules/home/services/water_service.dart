import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:intl/intl.dart';

class WaterService {
  final ApiService _api = ApiService();

  Map<String, dynamic> get _authHeaders => {'Authorization': 'Bearer $token'};

  /// Sync local water entries to backend (silent — background operation)
  Future<Map<String, dynamic>?> logWater({
    required String date,
    required List<Map<String, dynamic>> entries,
    int goal = 2500,
  }) async {
    try {
      final response = await _api.request(
        endPoint: '/water/log',
        method: 'POST',
        data: {'date': date, 'entries': entries, 'goal': goal},
        headers: _authHeaders,
        silent: true,
      );
      if (response != null && response.data != null) {
        if (response.data is String) {
          return {'success': false, 'message': response.data};
        }
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Get a given date's water log from backend (defaults to today) - the
  /// endpoint is date-parameterized despite its "/today" name (see
  /// waterController.js's getToday, which just reads req.query.date), so
  /// this also serves the Home screen's day-navigator browsing past days.
  Future<Map<String, dynamic>?> getToday({DateTime? date}) async {
    try {
      final localDate = DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());
      final response = await _api.request(
        endPoint: '/water/today',
        method: 'GET',
        queryParameters: {'date': localDate},
        headers: _authHeaders,
        silent: true,
      );
      if (response != null && response.data != null) {
        if (response.data is String) return null;
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Get water intake history for chart
  Future<List<dynamic>?> getHistory({int days = 7}) async {
    try {
      final response = await _api.request(
        endPoint: '/water/history',
        method: 'GET',
        queryParameters: {'days': days},
        headers: _authHeaders,
        silent: true,
      );
      if (response != null && response.data != null) {
        if (response.data is String) return null;
        final data = Map<String, dynamic>.from(response.data);
        if (data['success'] == true) return data['data'] as List<dynamic>?;
      }
    } catch (_) {}
    return null;
  }
}
