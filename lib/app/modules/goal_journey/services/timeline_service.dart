import 'dart:developer';

import 'package:docwellness/app/models/timeline_dto.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

/// Backend calls for the Goal Journey Timeline feature - built on the
/// shared ApiService wrapper, same as every other service in this app (not
/// a separate Dio/ApiClient singleton).
class TimelineService {
  final ApiService _api = ApiService();
  Map<String, String> get _authHeader => {'Authorization': 'Bearer $token'};

  Future<TimelineDto?> getTimeline({int from = -14, int to = 30}) async {
    try {
      final res = await _api.request(
        endPoint: '/timeline',
        method: 'GET',
        queryParameters: {'from': from, 'to': to},
        headers: _authHeader,
        silent: true,
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return TimelineDto.fromJson(Map<String, dynamic>.from(res.data['data']));
      }
    } catch (e) {
      log('TimelineService getTimeline error: $e');
    }
    return null;
  }

  Future<TimelineStats?> getSummary() async {
    try {
      final res = await _api.request(
        endPoint: '/timeline/summary',
        method: 'GET',
        headers: _authHeader,
        silent: true,
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'];
        if (data['stats'] == null) return null;
        return TimelineStats.fromJson(Map<String, dynamic>.from(data['stats']));
      }
    } catch (e) {
      log('TimelineService getSummary error: $e');
    }
    return null;
  }

  /// What this patient actually logged on [date] (meals + weight) - shown
  /// behind a tapped daily milestone node.
  Future<Map<String, dynamic>?> getDayLogs(DateTime date) async {
    try {
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await _api.request(
        endPoint: '/timeline/days/$dateStr/logs',
        method: 'GET',
        headers: _authHeader,
        silent: true,
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['data']);
      }
    } catch (e) {
      log('TimelineService getDayLogs error: $e');
    }
    return null;
  }

  Future<bool> checkIn({required String taskId, required String milestoneId, String? value}) async {
    try {
      final res = await _api.request(
        endPoint: '/check-ins',
        method: 'POST',
        data: {
          'taskId': taskId,
          'milestoneId': milestoneId,
          if (value != null) 'value': value,
        },
        headers: _authHeader,
        silent: true,
      );
      return res != null && res.statusCode == 201 && res.data['success'] == true;
    } catch (e) {
      log('TimelineService checkIn error: $e');
      return false;
    }
  }

  Future<bool> uncheckToday(String taskId) async {
    try {
      final res = await _api.request(
        endPoint: '/check-ins/today/$taskId',
        method: 'DELETE',
        headers: _authHeader,
        silent: true,
      );
      return res != null && res.statusCode == 200 && res.data['success'] == true;
    } catch (e) {
      log('TimelineService uncheckToday error: $e');
      return false;
    }
  }
}
