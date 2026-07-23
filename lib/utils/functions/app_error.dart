import 'package:dio/dio.dart';
import 'package:docwellness/app/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Central error handler for the app.
/// Call [AppError.handle] from any catch block.
/// Shows a user-friendly dialog — never leaks developer messages.
class AppError {
  AppError._();

  /// Auto-detects error type and shows the right dialog.
  static void handle(dynamic error) {
    if (error is DioException) {
      _handleDio(error);
    } else {
      _showDialog(
        title: 'Something went wrong',
        message: 'Please try again later.',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  static void _handleDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        // DioExceptionType.connectionError/.unknown just means "no response
        // came back" - that also happens for reasons that have nothing to do
        // with connectivity (a cold-start burst of concurrent requests
        // racing to open sockets, a one-off server hiccup). Cross-check
        // against ConnectivityService's actual last-known state before
        // claiming "No Internet" - this was firing on every first Home load
        // even with a good connection, purely because 6 requests fired at
        // once and one lost that race.
        final reallyOffline =
            Get.isRegistered<ConnectivityService>() &&
            Get.find<ConnectivityService>().isOffline;
        if (reallyOffline) {
          _showDialog(
            title: 'No Internet Connection',
            message: 'Please check your network and try again.',
            icon: Icons.wifi_off_rounded,
          );
        } else {
          _showDialog(
            title: 'Something went wrong',
            message: 'Please try again.',
            icon: Icons.error_outline_rounded,
          );
        }

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _showDialog(
          title: 'Connection Timeout',
          message:
              'The server is taking too long to respond. Please try again.',
          icon: Icons.timer_off_rounded,
        );

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        if (status >= 500) {
          _showDialog(
            title: 'Server Error',
            message: 'Something went wrong on our end. Please try again later.',
            icon: Icons.cloud_off_rounded,
          );
        } else if (status == 401) {
          _showDialog(
            title: 'Session Expired',
            message: 'Please log in again.',
            icon: Icons.lock_outline_rounded,
          );
        } else {
          // Extract backend message if present, otherwise generic
          final msg = _extractMessage(e.response?.data);
          _showDialog(
            title: 'Error',
            message: msg,
            icon: Icons.info_outline_rounded,
          );
        }

      default:
        _showDialog(
          title: 'Something went wrong',
          message: 'Please try again later.',
          icon: Icons.error_outline_rounded,
        );
    }
  }

  static String _extractMessage(dynamic data) {
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Something went wrong. Please try again.';
  }

  static void _showDialog({
    required String title,
    required String message,
    required IconData icon,
  }) {
    // Avoid stacking duplicate dialogs
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xffFDF2FA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: const Color(0xff6A0D33)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xff1F2A37),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff6C737F),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6A0D33),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }
}
