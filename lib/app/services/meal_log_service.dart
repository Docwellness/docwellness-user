import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../data/providers/api_provider.dart';

class MealLogService extends GetxService {
  static const _todayMealLogsPath = '/patient/meal-logs/today';
  static const _mealLogStatsPath = '/patient/meal-logs/stats';
  static const _mealLogsPath = '/patient/meal-logs';
  static const _mealNotesPath = '/patient/meal-notes';

  late Dio _dio;

  @override
  void onInit() {
    super.onInit();
    final apiProvider = Get.find<ApiProvider>();
    _dio = apiProvider.dio;
  }

  Future<Map<String, dynamic>> getTodayMealLogs() async {
    try {
      final response = await _dio.get(_todayMealLogsPath);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMealLogStats() async {
    try {
      final response = await _dio.get(_mealLogStatsPath);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllMealLogs({
    int page = 1,
    int limit = 20,
    String? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (date != null) {
        queryParams['date'] = date;
      }
      final response = await _dio.get(
        _mealLogsPath,
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMealLog({
    required String mealType,
    String? recipeId,
    int servings = 1,
    int caloriesConsumed = 0,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        _mealLogsPath,
        data: {
          'mealType': mealType,
          'recipeId': recipeId,
          'servings': servings,
          'caloriesConsumed': caloriesConsumed,
          'notes': notes,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMealLog({
    required String logId,
    required int mealIndex,
    int? servings,
    int? caloriesConsumed,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (servings != null) {
        data['servings'] = servings;
      }
      if (caloriesConsumed != null) {
        data['caloriesConsumed'] = caloriesConsumed;
      }
      if (notes != null) {
        data['notes'] = notes;
      }

      final response = await _dio.put(
        '$_mealLogsPath/$logId/meal/$mealIndex',
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteMealLog({
    required String logId,
    required int mealIndex,
  }) async {
    try {
      final response = await _dio.delete(
        '$_mealLogsPath/$logId/meal/$mealIndex',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeMeal({
    required String logId,
    required int mealIndex,
  }) async {
    try {
      final response = await _dio.post(
        '$_mealLogsPath/$logId/meal/$mealIndex/complete',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addMealNote({
    String? description,
    File? imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (description != null) 'description': description,
        if (imageFile != null)
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
      });

      final response = await _dio.post(_mealNotesPath, data: formData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  bool get isToday {
    return true;
  }
}
