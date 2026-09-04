import 'dart:async';

import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/views/motivation_view.dart';
import 'package:docwellness/app/modules/home/views/view_first_consultation_view.dart';
import 'package:docwellness/app/modules/home/widgets/request_diet_plan.view.dart';
import 'package:docwellness/app/modules/notifications/services/notification_service.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:get/get.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? referenceId;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.referenceId,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['isRead'] ?? false,
      referenceId: json['referenceId'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxInt unreadCount = 0.obs;

  int _currentPage = 1;
  int _totalPages = 1;
  StreamSubscription? _notifSub;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications().then((_) => _autoMarkAllRead());
    _listenForNewNotifications();
  }

  @override
  void onClose() {
    _notifSub?.cancel();
    super.onClose();
  }

  void _listenForNewNotifications() {
    final socket = Get.find<SocketService>();
    _notifSub = socket.onNotification.listen((data) {
      final item = NotificationItem(
        id: data['id']?.toString() ?? '',
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        type: data['type'] ?? 'system',
        isRead: false,
        referenceId: data['referenceId']?.toString(),
        createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      );
      notifications.insert(0, item);
      unreadCount.value++;
    });
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    _currentPage = 1;
    final data = await _service.getNotifications(page: 1);
    if (data != null) {
      final list = (data['notifications'] as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList();
      notifications.value = list;
      unreadCount.value = data['unreadCount'] ?? 0;
      final pagination = data['pagination'];
      _totalPages = pagination?['pages'] ?? 1;
    }
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || _currentPage >= _totalPages) return;
    isLoadingMore.value = true;
    _currentPage++;
    final data = await _service.getNotifications(page: _currentPage);
    if (data != null) {
      final list = (data['notifications'] as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList();
      notifications.addAll(list);
    }
    isLoadingMore.value = false;
  }

  Future<void> markAsRead(String id) async {
    final success = await _service.markAsRead(id);
    if (success) {
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !notifications[idx].isRead) {
        notifications[idx] = NotificationItem(
          id: notifications[idx].id,
          title: notifications[idx].title,
          message: notifications[idx].message,
          type: notifications[idx].type,
          isRead: true,
          referenceId: notifications[idx].referenceId,
          createdAt: notifications[idx].createdAt,
        );
        if (unreadCount.value > 0) unreadCount.value--;
      }
    }
  }

  Future<void> markAllAsRead() async {
    final success = await _service.markAllAsRead();
    if (success) {
      notifications.value = notifications
          .map(
            (n) => NotificationItem(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              referenceId: n.referenceId,
              createdAt: n.createdAt,
            ),
          )
          .toList();
      unreadCount.value = 0;
    }
  }

  Future<void> refreshUnreadCount() async {
    unreadCount.value = await _service.getUnreadCount();
  }

  /// Auto-mark all visible notifications as read
  Future<void> _autoMarkAllRead() async {
    if (unreadCount.value > 0) {
      await markAllAsRead();
    }
  }

  /// Navigate based on notification type
  void onTapNotification(NotificationItem item) {
    markAsRead(item.id);
    if (item.type == 'chat') {
      Get.toNamed(Routes.CHAT);
    } else if (item.type == 'quote') {
      Get.to(() => const MotivationScreen());
    } else if (item.type == 'consultation') {
      // Replace this screen rather than pushing on top of it, so the back
      // button from the form goes straight to Home instead of back here.
      Get.off(() => const ViewFirstConsultationView());
    } else if (item.type == 'payment') {
      // The payment action (the "Send Payment Details" button / sheet) lives
      // on Home - this screen is always pushed from there, so pop back to it.
      Get.back();
    } else if (item.type == 'membership_renewal') {
      // Same shortcut as the Home screen's "Request diet plan" renewal
      // button - skip the full intake form and jump straight to picking a
      // plan, since consultation/personal data already exists.
      Get.find<HomeController>().startRenewal().then((_) {
        Get.off(() => const RequestDietPlanScreen());
      });
    }
  }
}
