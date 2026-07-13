import 'package:docwellness/utils/common_widgets/web_view_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in an in-app WebView on mobile/desktop. True in-app WebViews
/// aren't possible in a browser (webview_flutter has no web implementation,
/// and most sites block being iframed anyway), so on Flutter Web this opens
/// a new browser tab instead - the closest equivalent on that platform.
Future<void> openWebLink({required String url, required String title}) async {
  if (kIsWeb) {
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    return;
  }
  await Get.to(() => WebViewScreen(title: title, url: url));
}
