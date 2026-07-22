import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Scroll-and-stitch screenshot helper.
/// Wraps a Scaffold in [RepaintBoundary] with [captureKey], and
/// attaches [scrollController] to the scrollable body.
class ScreenshotHelper {
  ScreenshotHelper._();

  /// Scroll through the page, capture each viewport, stitch into one tall image.
  /// If [scrollController] is null or not attached, tries to auto-discover the
  /// active ScrollController from the widget tree. Falls back to visible-only capture.
  static Future<Uint8List?> captureScrollableScreen({
    required BuildContext context,
    required GlobalKey captureKey,
    ScrollController? scrollController,
    double appBarHeight = 0,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final pixelRatio = MediaQuery.of(
        context,
      ).devicePixelRatio.clamp(1.0, 2.5);
      final viewportW = boundary.size.width;
      final viewportH = boundary.size.height;

      // Try to find an active ScrollController if none provided
      ScrollController? sc = scrollController;
      if (sc == null || !sc.hasClients) {
        sc = PrimaryScrollController.maybeOf(context);
      }

      // If not scrollable, just capture visible area
      if (sc == null || !sc.hasClients || sc.position.maxScrollExtent <= 0) {
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return byteData?.buffer.asUint8List();
      }

      final maxScroll = sc.position.maxScrollExtent;
      final originalScroll = sc.position.pixels;

      // Calculate AppBar height if not provided
      final topPadding = MediaQuery.of(context).padding.top;
      final appBarH = appBarHeight > 0
          ? appBarHeight
          : (kToolbarHeight + topPadding);
      final bodyH = viewportH - appBarH;

      if (bodyH <= 0) return null;

      final totalContentH = bodyH + maxScroll;
      final totalOutputH = appBarH + totalContentH;

      final scrollPositions = <double>[];
      final images = <ui.Image>[];

      double scrollPos = 0;
      while (true) {
        final clamped = scrollPos.clamp(0.0, maxScroll);
        sc.jumpTo(clamped);
        await Future.delayed(const Duration(milliseconds: 80));
        await WidgetsBinding.instance.endOfFrame;

        final img = await boundary.toImage(pixelRatio: pixelRatio);
        scrollPositions.add(clamped);
        images.add(img);

        if (clamped >= maxScroll) break;
        scrollPos += bodyH;
      }

      // Restore original scroll position
      sc.jumpTo(originalScroll);

      if (images.isEmpty) return null;

      final pr = pixelRatio;
      final outW = (viewportW * pr).ceil();
      final outH = (totalOutputH * pr).ceil();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );

      for (int i = 0; i < images.length; i++) {
        final img = images[i];
        final scroll = scrollPositions[i];

        if (i == 0) {
          canvas.drawImage(img, Offset.zero, Paint());
        } else {
          final srcTop = appBarH * pr;
          final srcH = bodyH * pr;
          final dstTop = (appBarH + scroll) * pr;

          canvas.drawImageRect(
            img,
            Rect.fromLTWH(0, srcTop, outW.toDouble(), srcH),
            Rect.fromLTWH(0, dstTop, outW.toDouble(), srcH),
            Paint(),
          );
        }
      }

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(outW, outH);
      final byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      for (final img in images) {
        img.dispose();
      }
      finalImage.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing screen: $e');
      return null;
    }
  }

  /// Share the captured screenshot
  static Future<void> shareScreen({
    required BuildContext context,
    required GlobalKey captureKey,
    ScrollController? scrollController,
    double appBarHeight = 0,
    String filePrefix = 'screenshot',
    String shareText = 'Shared from Docwellness',
  }) async {
    final bytes = await captureScrollableScreen(
      context: context,
      captureKey: captureKey,
      scrollController: scrollController,
      appBarHeight: appBarHeight,
    );
    if (bytes == null || bytes.isEmpty) {
      showAppToast(
        Get.overlayContext!,
        message: 'Could not capture screen. Please try again.',
        type: AppToastType.error,
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: shareText),
    );
  }

  /// Download the captured screenshot to gallery
  static Future<void> downloadScreen({
    required BuildContext context,
    required GlobalKey captureKey,
    ScrollController? scrollController,
    double appBarHeight = 0,
    String filePrefix = 'screenshot',
  }) async {
    final hasPermission = await _ensureGalleryPermission();
    if (!hasPermission) {
      showAppToast(
        Get.overlayContext!,
        message:
            'Permission required: Please allow photo/storage access to save screenshots.',
        type: AppToastType.warning,
      );
      return;
    }

    final bytes = await captureScrollableScreen(
      context: context,
      captureKey: captureKey,
      scrollController: scrollController,
      appBarHeight: appBarHeight,
    );
    if (bytes == null || bytes.isEmpty) {
      showAppToast(
        Get.overlayContext!,
        message: 'Could not capture screen. Please try again.',
        type: AppToastType.error,
      );
      return;
    }

    final fileName = '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}';
    final result = await ImageGallerySaverPlus.saveImage(
      bytes,
      quality: 100,
      name: fileName,
    );

    final isSuccess =
        result != null &&
        (result['isSuccess'] == true || result['success'] == true);

    if (isSuccess) {
      showAppToast(
        Get.overlayContext!,
        message: 'Screenshot downloaded to gallery.',
        type: AppToastType.success,
      );
      return;
    }

    showAppToast(
      Get.overlayContext!,
      message: 'Could not save screenshot. Check storage permissions.',
      type: AppToastType.error,
    );
  }

  /// Show share/download bottom sheet
  static void showShareDownloadSheet({
    required BuildContext context,
    required GlobalKey captureKey,
    ScrollController? scrollController,
    double appBarHeight = 0,
    String filePrefix = 'screenshot',
    String shareText = 'Shared from Docwellness',
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: const Text('Share screenshot'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await shareScreen(
                      context: context,
                      captureKey: captureKey,
                      scrollController: scrollController,
                      appBarHeight: appBarHeight,
                      filePrefix: filePrefix,
                      shareText: shareText,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Download screenshot'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await downloadScreen(
                      context: context,
                      captureKey: captureKey,
                      scrollController: scrollController,
                      appBarHeight: appBarHeight,
                      filePrefix: filePrefix,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool> _ensureGalleryPermission() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    if (Platform.isIOS) {
      final photos = await Permission.photosAddOnly.request();
      return photos.isGranted || photos.isLimited;
    }
    return true;
  }
}
