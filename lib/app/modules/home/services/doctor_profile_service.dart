import 'package:docwellness/app/models/article_model.dart';
import 'package:docwellness/app/models/doctor_profile_model.dart';
import 'package:docwellness/app/models/review_model.dart';
import 'package:docwellness/app/models/social_media_post_model.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

class DoctorProfileService {
  final ApiService _apiService = ApiService();

  Future<DoctorProfileModel?> getAssignedDoctorProfile({
    bool silent = false,
  }) async {
    try {
      final response = await _apiService.request(
        endPoint: '/assigned-doctor/profile',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        silent: silent,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return DoctorProfileModel.fromJson(response.data['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getDoctorPosts() async {
    try {
      final response = await _apiService.request(
        endPoint: '/quotes',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  /// Returns {'youtube': [...], 'instagram': [...]}.
  Future<Map<String, List<SocialMediaPostModel>>> getSocialMediaPosts() async {
    try {
      final response = await _apiService.request(
        endPoint: '/social-media',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        return {
          'youtube': (data['youtube'] as List? ?? [])
              .map((e) => SocialMediaPostModel.fromJson(e))
              .toList(),
          'instagram': (data['instagram'] as List? ?? [])
              .map((e) => SocialMediaPostModel.fromJson(e))
              .toList(),
        };
      }
    } catch (_) {}
    return {'youtube': [], 'instagram': []};
  }

  Future<List<ArticleModel>> getArticles() async {
    try {
      final response = await _apiService.request(
        endPoint: '/articles',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return (response.data['data'] as List? ?? [])
            .map((e) => ArticleModel.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Returns {'reviews': [...], 'averageRating': double, 'myReviewId': String?}.
  Future<Map<String, dynamic>> getReviews() async {
    try {
      final response = await _apiService.request(
        endPoint: '/reviews',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final myReview = data['myReview'] as Map<String, dynamic>?;
        return {
          'reviews': (data['reviews'] as List? ?? [])
              .map((e) => ReviewModel.fromJson(e))
              .toList(),
          'averageRating': (data['averageRating'] as num?)?.toDouble() ?? 0.0,
          'myReview': myReview != null ? ReviewModel.fromJson(myReview) : null,
        };
      }
    } catch (_) {}
    return {'reviews': <ReviewModel>[], 'averageRating': 0.0, 'myReview': null};
  }

  Future<bool> submitReview({required int rating, required String text}) async {
    try {
      final response = await _apiService.request(
        endPoint: '/reviews',
        method: 'POST',
        data: {'rating': rating, 'text': text},
        headers: {'Authorization': 'Bearer $token'},
      );

      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
