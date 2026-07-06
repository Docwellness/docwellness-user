import 'dart:async';

import 'package:docwellness/app/models/conversation_model.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/app/services/chat_service.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatListController extends GetxController {
  final ChatService _chatService = ChatService();
  late SocketService _socketService;

  // UI Controllers
  final TextEditingController searchController = TextEditingController();

  // Observables
  final RxList<ConversationModel> conversations = <ConversationModel>[].obs;
  final RxList<ConversationModel> filteredConversations =
      <ConversationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Stream subscriptions
  StreamSubscription? _messageSubscription;

  @override
  void onInit() {
    super.onInit();
    _initSocketService();
    fetchConversations();

    // Listen to search changes
    debounce(
      searchQuery,
      (_) => _filterConversations(),
      time: const Duration(milliseconds: 300),
    );
  }

  void _initSocketService() {
    try {
      _socketService = Get.find<SocketService>();
    } catch (e) {
      _socketService = Get.put(SocketService());
    }

    // Ensure socket is connected
    if (!_socketService.isConnected.value) {
      _socketService.connect();
    }

    // Listen for new messages to update conversation list
    _messageSubscription = _socketService.onMessage.listen((data) {
      _updateConversationWithMessage(data);
    });
  }

  Future<void> fetchConversations() async {
    isLoading.value = true;

    final fetchedConversations = await _chatService.getConversations();
    conversations.assignAll(fetchedConversations);
    _filterConversations();

    isLoading.value = false;
  }

  void _filterConversations() {
    if (searchQuery.value.isEmpty) {
      filteredConversations.assignAll(conversations);
    } else {
      filteredConversations.assignAll(
        conversations
            .where(
              (conv) => conv.displayName.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ),
            )
            .toList(),
      );
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void _updateConversationWithMessage(Map<String, dynamic> messageData) {
    final conversationId = messageData['conversationId'];
    final index = conversations.indexWhere((c) => c.id == conversationId);

    if (index != -1) {
      final conv = conversations[index];
      final updatedConv = ConversationModel(
        id: conv.id,
        participants: conv.participants,
        patientId: conv.patientId,
        doctorId: conv.doctorId,
        otherUser: conv.otherUser,
        lastMessage: LastMessage(
          content: messageData['content'] ?? '',
          timestamp: DateTime.now(),
          senderId: messageData['senderId'] ?? '',
        ),
        unreadCount: conv.unreadCount + 1,
        createdAt: conv.createdAt,
        updatedAt: DateTime.now(),
      );

      // Move to top and update
      conversations.removeAt(index);
      conversations.insert(0, updatedConv);
      _filterConversations();
    } else {
      // New conversation - refresh list
      fetchConversations();
    }
  }

  void openChat(ConversationModel conversation) {
    // Mark as read locally
    final index = conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      conversations[index] = ConversationModel(
        id: conversation.id,
        participants: conversation.participants,
        patientId: conversation.patientId,
        doctorId: conversation.doctorId,
        otherUser: conversation.otherUser,
        lastMessage: conversation.lastMessage,
        unreadCount: 0,
        createdAt: conversation.createdAt,
        updatedAt: conversation.updatedAt,
      );
      _filterConversations();
    }

    Get.toNamed(Routes.CHAT, arguments: conversation);
  }

  int get totalUnreadCount {
    return conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  @override
  void onClose() {
    searchController.dispose();
    _messageSubscription?.cancel();
    super.onClose();
  }
}
