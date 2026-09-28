import 'dart:developer';
import 'dart:io';

import 'package:docwellness/app/services/push_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests notifications (via PushNotificationService, which also finishes
/// wiring up the FCM device-token registration) and the photo-library
/// permission together, right after signup completes and the user lands on
/// Home for the first time - see AuthController.completeRegistration. Doing
/// this here means both prompts surface as one sequence in that moment
/// instead of notifications trickling in on the next cold start (main.dart's
/// own PushNotificationService().init() call is gated on an already-signed-in
/// userId, which isn't set yet the first time main() runs for a brand new
/// signup) and photo access separately, later, on first saving a progress
/// screenshot.
Future<void> requestStartupPermissions() async {
  await PushNotificationService().init();

  try {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (!photos.isGranted && !photos.isLimited) {
        await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      await Permission.photosAddOnly.request();
    }
  } catch (e) {
    log('requestStartupPermissions: photo permission failed: $e');
  }
}
