import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

class NotificationService {
  final ApiService _api = ApiService();
  Map<String, String> get _authHeader => {'Authorization': 'Bearer $token'};

  Future<Map<String, dynamic>?> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.request(
        endPoint: '/notifications',
        method: 'GET',
        queryParameters: {'page': page, 'limit': limit},
        headers: _authHeader,
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _api.request(
        endPoint: '/notifications/unread-count',
        method: 'GET',
        headers: _authHeader,
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']['unreadCount'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _api.request(
        endPoint: '/notifications/$id/read',
        method: 'PUT',
        headers: _authHeader,
      );
      return response != null && response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _api.request(
        endPoint: '/notifications/read-all',
        method: 'PUT',
        headers: _authHeader,
      );
      return response != null && response.statusCode == 200;
    } catch (_) {}
    return false;
  }
}
