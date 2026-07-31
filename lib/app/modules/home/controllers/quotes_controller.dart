import 'dart:async';
import 'dart:developer';

import 'package:docwellness/app/modules/home/widgets/quote_of_the_day_dialog.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns QuotesSection's data - same reasoning as VideosController (see its
/// doc comment): previously lived entirely inside _QuotesSectionState's own
/// initState with no way for a Home pull-to-refresh to trigger it again.
/// Also switches onto the shared ApiService instead of the widget's own
/// raw Dio instance, so it inherits the same silent/error-dialog handling
/// every other call in the app already gets.
class QuotesController extends GetxController {
  final ApiService _api = ApiService();

  // Persists which quote's popup the user has already seen/dismissed, so
  // the same quote doesn't re-pop on every app relaunch - only a genuinely
  // new latest quote (or one they never got to dismiss) does.
  static const _lastSeenQuoteIdKey = 'last_seen_quote_id';

  RxList<Map<String, dynamic>> quotes = <Map<String, dynamic>>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Only this very first fetch (QuotesController is `permanent: true`, put
    // once per app session - see main.dart/quotes_section.dart) should ever
    // offer the "app just opened" popup; later refreshes (pull-to-refresh,
    // HomeController.refreshAllData) must not re-trigger it.
    fetchQuotes(showLatestIfNew: true);
  }

  Future<void> fetchQuotes({bool showLatestIfNew = false}) async {
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
        if (showLatestIfNew) unawaited(_maybeShowLatestQuoteDialog());
        return;
      }
    } catch (e) {
      log('QuotesController fetch error: $e');
    }
    isLoading.value = false;
  }

  Future<void> _maybeShowLatestQuoteDialog() async {
    if (quotes.isEmpty) return;
    // Backend already returns quotes sorted by createdAt desc, so the first
    // entry is the latest one.
    final latest = quotes.first;
    final id = latest['_id'] as String? ?? '';
    final imageUrl = latest['imageUrl'] as String? ?? '';
    if (id.isEmpty || imageUrl.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_lastSeenQuoteIdKey) == id) return;
    if (Get.isDialogOpen == true) return;

    await Get.dialog(
      QuoteOfTheDayDialog(
        imageUrl: imageUrl,
        quoteText: latest['text'] as String? ?? '',
      ),
      barrierColor: Colors.transparent,
    );
    await prefs.setString(_lastSeenQuoteIdKey, id);
  }
}
