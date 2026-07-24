import 'dart:developer';

import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:get/get.dart';

/// Owns QuotesSection's data - same reasoning as VideosController (see its
/// doc comment): previously lived entirely inside _QuotesSectionState's own
/// initState with no way for a Home pull-to-refresh to trigger it again.
/// Also switches onto the shared ApiService instead of the widget's own
/// raw Dio instance, so it inherits the same silent/error-dialog handling
/// every other call in the app already gets.
class QuotesController extends GetxController {
  final ApiService _api = ApiService();

  RxList<Map<String, dynamic>> quotes = <Map<String, dynamic>>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchQuotes();
  }

  Future<void> fetchQuotes() async {
    isLoading.value = true;
    try {
      final res = await _api.request(
        endPoint: '/quotes',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        silent: true,
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        quotes.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        isLoading.value = false;
        return;
      }
    } catch (e) {
      log('QuotesController fetch error: $e');
    }
    isLoading.value = false;
  }
}
