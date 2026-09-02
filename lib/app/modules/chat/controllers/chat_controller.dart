import 'dart:async';
import 'dart:developer';

import 'package:docwellness/app/models/conversation_model.dart';
import 'package:docwellness/app/models/message_model.dart';
import 'package:docwellness/app/services/chat_service.dart';
import 'package:docwellness/app/services/socket_service.dart';
import 'package:docwellness/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class ChatController extends GetxController {
  final ChatService _chatService = ChatService();
  late SocketService _socketService;

  // UI Controllers
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  // Observables
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isTyping = false.obs;
  final RxString typingUserId = ''.obs;
  final RxBool hasText = false.obs;
  final Rx<ConversationModel?> conversation = Rx<ConversationModel?>(null);
  final Rx<ChatUserModel?> otherUser = Rx<ChatUserModel?>(null);

  // Reply
  final Rx<MessageModel?> replyMessage = Rx<MessageModel?>(null);
  MessageModel? get replyingTo => replyMessage.value;

  void setReply(MessageModel message) {
    replyMessage.value = message;
  }

  void clearReply() {
    replyMessage.value = null;
  }

  // Tap-to-scroll on a quoted reply preview: keyed so a widget already
  // built in the (reverse) ListView can be located and scrolled into view,
  // then briefly flashed like WhatsApp's jump-to-original behavior.
  final Map<String, GlobalKey> messageKeys = {};
  final RxString highlightedMessageId = ''.obs;
  Timer? _highlightTimer;

  GlobalKey keyFor(String id) =>
      messageKeys.putIfAbsent(id, () => GlobalKey());

  Future<void> scrollToMessage(String? id) async {
    if (id == null || id.isEmpty) return;
    final key = messageKeys[id];
    final ctx = key?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.3,
      );
    }
    highlightedMessageId.value = id;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1200), () {
      highlightedMessageId.value = '';
    });
  }

  // Pagination - cursor based. `messages` is kept newest-first, so the
  // oldest loaded message's timestamp is the cursor for the next older page
  // (`?before=`). Cursor paging is stable when a new message arrives while
  // the user is scrolling back through history (offset paging is not).
  bool hasMoreMessages = true;
  final int messagesPerPage = 50;
  bool _isLoadingOlder = false;

  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _readSubscription;
  StreamSubscription? _customFoodStatusSubscription;

  // Typing debounce
  Timer? _typingTimer;

  @override
  void onInit() {
    super.onInit();
    // Set current user ID for message model
    MessageModel.setCurrentUserId(userId ?? '');

    // Initialize socket service
    _initSocketService();

    // Get arguments
    final args = Get.arguments;
    if (args != null) {
      if (args is ConversationModel) {
        conversation.value = args;
        otherUser.value = args.otherUser;
        _joinConversation(args.id);
        fetchMessages();
      } else if (args is Map<String, dynamic>) {
        if (args['conversationId'] != null) {
          _joinConversation(args['conversationId']);
          fetchMessages();
        } else if (args['doctorId'] != null) {
          _getOrCreateConversation(args['doctorId']);
        }
        if (args['otherUser'] != null) {
          otherUser.value = args['otherUser'];
        }
      }
    } else {
      // No arguments - get assigned doctor for patient
      _getAssignedDoctorAndStartChat();
    }

    // Setup scroll listener for pagination
    scrollController.addListener(_onScroll);
  }

  void _initSocketService() {
    try {
      _socketService = Get.find<SocketService>();
    } catch (e) {
      _socketService = Get.put(SocketService());
    }

    // Ensure socket is connected when entering chat
    if (!_socketService.isConnected.value) {
      _socketService.connect();
    }

    // Listen for new messages
    _messageSubscription = _socketService.onMessage.listen((data) {
      final message = MessageModel.fromJson(data);
      if (message.conversationId == conversation.value?.id) {
        // Dedup by id OR clientMessageId (see MessageModel.isDuplicate's
        // doc comment for why clientMessageId matters, not just id) - the
        // sender is joined to this conversation's socket room (see
        // _joinConversation), so their own just-sent message can be
        // echoed back here before the REST response in sendMessage()/
        // sendImageMessage() has replaced the optimistic entry's temp id
        // with the real server id.
        if (!MessageModel.isDuplicate(messages, message)) {
          messages.insert(0, message);
          _scrollToBottom();

          // Auto-mark incoming messages as read since we're viewing the chat
          if (message.senderId != userId && conversation.value != null) {
            _socketService.markAsRead(conversation.value!.id);
          }
        }
      }
    });

    // Listen for typing indicators
    _typingSubscription = _socketService.onTyping.listen((data) {
      if (data['conversationId'] == conversation.value?.id) {
        if (data['userId'] != userId) {
          isTyping.value = data['isTyping'] ?? true;
          typingUserId.value = data['userId'] ?? '';
        }
      }
    });

    // Listen for read receipts
    _readSubscription = _socketService.onRead.listen((data) {
      final readConvId = data['conversationId'] ?? data['conversation_id'];
      if (readConvId == conversation.value?.id) {
        // Update read status of messages
        for (var i = 0; i < messages.length; i++) {
          if (!messages[i].isRead && messages[i].senderId == userId) {
            messages[i] = MessageModel(
              id: messages[i].id,
              conversationId: messages[i].conversationId,
              senderId: messages[i].senderId,
              receiverId: messages[i].receiverId,
              content: messages[i].content,
              messageType: messages[i].messageType,
              metadata: messages[i].metadata,
              isRead: true,
              readAt: DateTime.now(),
              createdAt: messages[i].createdAt,
            );
          }
        }
        messages.refresh();
      }
    });

    // Listen for custom food status updates (doctor approve/reject)
    _customFoodStatusSubscription = _socketService.onCustomFoodStatus.listen((
      data,
    ) {
      log('🍽️ Custom food status update received: $data');
      final requestId = data['requestId']?.toString() ?? '';
      final newStatus = data['status']?.toString() ?? '';
      if (requestId.isEmpty || newStatus.isEmpty) return;

      // Find and update matching messages in the list
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        if (msg.messageType == MessageType.customFood) {
          final meta = msg.metadata;
          // Match by customFoodRequestId in metadata
          final metaJson = meta?.toJson() ?? {};
          final msgRequestId =
              metaJson['customFoodRequestId']?.toString() ?? '';
          if (msgRequestId == requestId) {
            // Rebuild metadata with updated status
            final updatedMeta = MessageMetadata.fromJson({
              ...metaJson,
              'status': newStatus,
              'action': newStatus,
            });
            messages[i] = MessageModel(
              id: msg.id,
              conversationId: msg.conversationId,
              senderId: msg.senderId,
              receiverId: msg.receiverId,
              content: msg.content,
              messageType: msg.messageType,
              attachment: msg.attachment,
              description: msg.description,
              metadata: updatedMeta,
              isRead: msg.isRead,
              readAt: msg.readAt,
              createdAt: msg.createdAt,
            );
            break;
          }
        }
      }
      messages.refresh();
    });
  }

  void _joinConversation(String conversationId) {
    _socketService.joinRoom(conversationId);
    _socketService.markAsRead(conversationId);
    // Also persist read status via REST API
    _chatService.markAsRead(conversationId);
  }

  Future<void> _getOrCreateConversation(String participantId) async {
    isLoading.value = true;
    final conv = await _chatService.getOrCreateConversation(participantId);
    if (conv != null) {
      conversation.value = conv;
      otherUser.value = conv.otherUser;
      _joinConversation(conv.id);
      // Reset loading before fetching messages so fetchMessages doesn't skip
      isLoading.value = false;
      await fetchMessages();
    } else {
      isLoading.value = false;
    }
  }

  Future<void> _getAssignedDoctorAndStartChat() async {
    isLoading.value = true;
    final doctor = await _chatService.getAssignedDoctor();
    if (doctor != null) {
      otherUser.value = doctor;
      // Don't reset loading here - let _getOrCreateConversation handle it
      isLoading.value = false;
      await _getOrCreateConversation(doctor.id);
    } else {
      log('❌ No assigned doctor found');
      isLoading.value = false;
      // Show error or default state
    }
  }

  Future<void> fetchMessages({bool refresh = false}) async {
    if (conversation.value == null) return;
    if (isLoading.value && !refresh) return;
    if (_isLoadingOlder && !refresh) return;

    final loadingOlder = !refresh && messages.isNotEmpty;
    if (loadingOlder) {
      _isLoadingOlder = true;
    } else {
      if (refresh) {
        hasMoreMessages = true;
        messages.clear();
      }
      isLoading.value = true;
    }

    // messages is newest-first, so the last entry is the oldest loaded - the
    // cursor for the next (older) page. null on a fresh/refresh load.
    final String? before = loadingOlder
        ? messages.last.createdAt.toUtc().toIso8601String()
        : null;

    final fetchedMessages = await _chatService.getMessages(
      conversation.value!.id,
      before: before,
      limit: messagesPerPage,
    );

    if (fetchedMessages.isNotEmpty) {
      fetchedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // Guard against the rare cursor-boundary overlap when a message lands
      // via socket mid-scroll.
      final fresh = fetchedMessages
          .where((m) => !messages.any((e) => e.id == m.id))
          .toList();

      if (refresh || !loadingOlder) {
        messages.assignAll(fresh);
      } else {
        messages.addAll(fresh);
      }
      hasMoreMessages = fetchedMessages.length >= messagesPerPage;
    } else {
      hasMoreMessages = false;
    }

    _isLoadingOlder = false;
    isLoading.value = false;
  }

  void _onScroll() {
    // Load older messages when scrolled to the top (list is reversed, so the
    // top is maxScrollExtent).
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (hasMoreMessages && !isLoading.value && !_isLoadingOlder) {
        fetchMessages();
      }
    }
  }

  void sendMessage() async {
    final content = messageController.text.trim();
    log('📤 sendMessage called with content: "$content"');
    log(
      '📤 conversation: ${conversation.value?.id}, otherUser: ${otherUser.value?.id}',
    );

    if (content.isEmpty) {
      log('❌ Content is empty, returning');
      return;
    }
    if (conversation.value == null || otherUser.value == null) {
      log('❌ conversation or otherUser is null, returning');
      return;
    }

    // Capture reply before clearing
    final currentReplyTo = replyingTo;
    final replyToId = currentReplyTo?.id;

    messageController.clear();
    hasText.value = false;
    isSending.value = true;
    _stopTyping();
    clearReply();

    // Create optimistic message
    final clientMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempMessage = MessageModel(
      id: clientMessageId,
      conversationId: conversation.value!.id,
      senderId: userId ?? '',
      receiverId: otherUser.value!.id,
      content: content,
      messageType: MessageType.text,
      isRead: false,
      createdAt: DateTime.now(),
      clientMessageId: clientMessageId,
    );

    // Add to UI immediately
    messages.insert(0, tempMessage);
    _scrollToBottom();

    // Persist via REST. Backend will broadcast `msg.new` over socket to the
    // receiver — DO NOT also emit via socket here, otherwise the message gets
    // saved twice (V1 + legacy Chat) and the receiver sees duplicates.
    final response = await _chatService.sendMessage(
      conversationId: conversation.value!.id,
      receiverId: otherUser.value!.id,
      content: content,
      replyTo: replyToId,
    );

    if (response != null) {
      // Replace optimistic message with server message
      final index = messages.indexWhere((m) => m.id == clientMessageId);
      if (index != -1) {
        messages[index] = response;
      }
      // AI_EXECUTION_PLAN.md Phase 8, P8-04 - no PHI: never the message
      // content itself, only that a text message was sent.
      Posthog().capture(
        eventName: 'chat_message_sent',
        properties: {'message_type': 'text'},
      );
    }

    isSending.value = false;
  }

  void sendImageMessage(XFile imageFile) async {
    if (conversation.value == null || otherUser.value == null) return;

    isSending.value = true;

    // Upload image first
    final imageUrl = await _chatService.uploadImage(imageFile);
    if (imageUrl != null) {
      final clientMessageId = DateTime.now().millisecondsSinceEpoch.toString();
      final tempMessage = MessageModel(
        id: clientMessageId,
        conversationId: conversation.value!.id,
        senderId: userId ?? '',
        receiverId: otherUser.value!.id,
        content: '',
        attachment: imageUrl,
        messageType: MessageType.image,
        isRead: false,
        createdAt: DateTime.now(),
        clientMessageId: clientMessageId,
      );

      // Add to UI immediately, same as sendMessage().
      messages.insert(0, tempMessage);
      _scrollToBottom();

      // Persist via REST (same pattern/reasoning as sendMessage(): the
      // backend broadcasts msg.new over socket to the receiver, so sending
      // over the socket directly here would double-save/duplicate it).
      final response = await _chatService.sendMessage(
        conversationId: conversation.value!.id,
        receiverId: otherUser.value!.id,
        content: imageUrl,
        messageType: 'image',
      );

      if (response != null) {
        final index = messages.indexWhere((m) => m.id == clientMessageId);
        if (index != -1) {
          messages[index] = response;
        }
      }
    }

    isSending.value = false;
  }

  void onTextChanged(String text) {
    hasText.value = text.isNotEmpty;
    if (text.isNotEmpty) {
      _sendTyping();
    } else {
      _stopTyping();
    }
  }

  void _sendTyping() {
    if (conversation.value == null) return;

    _socketService.sendTyping(conversation.value!.id);

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    if (conversation.value == null) return;

    _typingTimer?.cancel();
    _socketService.sendStopTyping(conversation.value!.id);
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> sendMealNote({
    XFile? imageFile,
    required String description,
  }) async {
    if (conversation.value == null || otherUser.value == null) return;
    if (description.trim().isEmpty) return;

    isSending.value = true;

    final result = await _chatService.sendMealNote(
      imageFile: imageFile,
      description: description,
    );

    if (result != null) {
      messages.insert(0, result);
      _scrollToBottom();
    }

    isSending.value = false;
  }

  Future<Map<String, dynamic>?> getTodayMealStats() async {
    return await _chatService.getTodayMealStats();
  }

  String getMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  bool shouldShowDateSeparator(int index) {
    if (index == messages.length - 1) return true;

    final currentDate = DateTime(
      messages[index].createdAt.year,
      messages[index].createdAt.month,
      messages[index].createdAt.day,
    );
    final previousDate = DateTime(
      messages[index + 1].createdAt.year,
      messages[index + 1].createdAt.month,
      messages[index + 1].createdAt.day,
    );

    return currentDate != previousDate;
  }

  String getDateSeparatorText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    _typingTimer?.cancel();
    _highlightTimer?.cancel();
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readSubscription?.cancel();
    _customFoodStatusSubscription?.cancel();

    if (conversation.value != null) {
      _socketService.leaveRoom(conversation.value!.id);
    }

    super.onClose();
  }
}
