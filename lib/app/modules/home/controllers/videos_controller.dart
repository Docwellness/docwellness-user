import 'dart:developer';

import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:get/get.dart';

/// Owns VideosSection's data so a Home pull-to-refresh can actually
/// re-fetch it - previously this lived entirely inside
/// _VideosSectionState's own initState, with no way for anything outside
/// that widget to trigger it again (confirmed live: toggling a video's
/// visibility on the dietician side never showed up on Home after
/// repeated pull-to-refresh). Registered permanent: true in main.dart's
/// _bootstrap, same lifecycle as DietController/WaterController.
class VideosController extends GetxController {
  final ApiService _api = ApiService();

  RxList<Map<String, dynamic>> videos = <Map<String, dynamic>>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    isLoading.value = true;
    try {
      final res = await _api.request(
        endPoint: '/videos',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        silent: true,
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        videos.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        isLoading.value = false;
        return;
      }
    } catch (e) {
      log('VideosController fetch error: $e');
    }
    isLoading.value = false;
  }
}
