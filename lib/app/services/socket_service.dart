import 'dart:async';
import 'dart:developer';

import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/main.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService extends GetxService with WidgetsBindingObserver {
  static SocketService get to => Get.find<SocketService>();

  IO.Socket? _socket;
  final String baseUrl = AppConfig.baseUrl;

  final RxBool isConnected = false.obs;
  final RxString currentRoom = ''.obs;

  // Stream controllers for different events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  final _mealLogController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _customFoodStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onRead => _readController.stream;
  Stream<Map<String, dynamic>> get onMealLogUpdate => _mealLogController.stream;
  Stream<Map<String, dynamic>> get onPresence => _presenceController.stream;
  Stream<Map<String, dynamic>> get onCustomFoodStatus =>
      _customFoodStatusController.stream;
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconnect socket when app comes back to foreground
      if (_socket == null || !_socket!.connected) {
        log('🔄 App resumed — reconnecting socket');
        connect();
      }
    }
  }

  Future<SocketService> init() async {
    connect();
    return this;
  }

  void connect() {
    if (_socket != null && _socket!.connected) {
      log('Socket already connected');
      return;
    }

    log('🔌 Connecting to socket: $baseUrl');

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.maxFinite.toInt())
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setAuth({'token': token ?? ''})
          .build(),
    );

    _setupEventListeners();
    _socket!.connect();
  }

  void _setupEventListeners() {
    _socket!.onConnect((_) {
      log('✅ Socket connected');
      isConnected.value = true;
    });

    _socket!.on('ws.auth_ok', (data) {
      log('✅ Socket authenticated: $data');
    });

    _socket!.onDisconnect((_) {
      log('❌ Socket disconnected');
      isConnected.value = false;
    });

    _socket!.onConnectError((error) {
      log('❌ Socket connection error: $error');
      isConnected.value = false;
    });

    _socket!.onError((error) {
      log('❌ Socket error: $error');
    });

    // ==========================================
    // v1 API Events (new format)
    // ==========================================

    // New message received
    _socket!.on('msg.new', (data) {
      log('📩 [v1] New message: $data');
      final map = _toMap(data);
      // Extract message from nested structure if present
      if (map['message'] != null) {
        final message = Map<String, dynamic>.from(map['message'] as Map);
        message['conversationId'] =
            message['conversationId'] ?? map['conversation_id'];
        _messageController.add(message);
      } else {
        _messageController.add(map);
      }
    });

    // Message acknowledgement
    _socket!.on('msg.ack', (data) {
      log('✅ [v1] Message ack: $data');
      _messageController.add({..._toMap(data), 'type': 'ack'});
    });

    // Message status update
    _socket!.on('msg.status', (data) {
      log('📬 [v1] Message status: $data');
      _readController.add(_toMap(data));
    });

    // Message updated (meal log updates)
    _socket!.on('msg.updated', (data) {
      log('🔄 [v1] Message updated: $data');
      _mealLogController.add(_toMap(data));
    });

    // Typing indicator
    _socket!.on('typing', (data) {
      log('⌨️ [v1] Typing: $data');
      _typingController.add(_toMap(data));
    });

    // Presence update
    _socket!.on('presence.update', (data) {
      log('👤 [v1] Presence: $data');
      _presenceController.add(_toMap(data));
    });

    // Conversation read
    _socket!.on('conv.read', (data) {
      log('👁️ [v1] Conversation read: $data');
      _readController.add(_toMap(data));
    });

    // Chat joined
    _socket!.on('chat.joined', (data) {
      log('✅ [v1] Joined chat: $data');
      currentRoom.value = data['conversation_id'] ?? '';
    });

    // ==========================================
    // Legacy Events (backward compatibility)
    // ==========================================

    _socket!.on('new_message', (data) {
      log('📩 [Legacy] New message: $data');
      _messageController.add(_toMap(data));
    });

    // newMessage - camelCase variant from backend
    _socket!.on('newMessage', (data) {
      log('📩 [Legacy] newMessage (camelCase): $data');
      _messageController.add(_toMap(data));
    });

    _socket!.on('message_sent', (data) {
      log('✅ [Legacy] Message sent: $data');
      _messageController.add(_toMap(data));
    });

    _socket!.on('receive_message', (data) {
      log('📩 [Legacy] Receive message: $data');
      _messageController.add(_toMap(data));
    });

    _socket!.on('user_typing', (data) {
      log('⌨️ [Legacy] User typing: $data');
      _typingController.add({..._toMap(data), 'typing': true});
    });

    _socket!.on('user_stop_typing', (data) {
      log('⌨️ [Legacy] User stop typing: $data');
      _typingController.add({..._toMap(data), 'typing': false});
    });

    _socket!.on('user_stopped_typing', (data) {
      log('⌨️ [Legacy] User stopped typing: $data');
      _typingController.add({..._toMap(data), 'typing': false});
    });

    _socket!.on('messages_read', (data) {
      log('👁️ [Legacy] Messages read: $data');
      _readController.add(_toMap(data));
    });

    _socket!.on('meal_log_update', (data) {
      log('🍽️ [Legacy] Meal log update: $data');
      _mealLogController.add(_toMap(data));
    });

    _socket!.on('diet_plan_update', (data) {
      log('📋 [Legacy] Diet plan update: $data');
      _mealLogController.add(_toMap(data));
    });

    // Custom food request status update (from doctor approve/reject)
    _socket!.on('custom_food_status', (data) {
      log('🍽️ Custom food status update: $data');
      _customFoodStatusController.add(_toMap(data));
    });

    // Notification events
    _socket!.on('notification.new', (data) {
      log('🔔 New notification: $data');
      _notificationController.add(_toMap(data));
    });
  }

  /// Helper to convert dynamic data to Map
  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  // ==========================================
  // v1 API Methods
  // ==========================================

  /// Join a conversation room
  void joinConversation(String conversationId) {
    log('📥 Joining conversation: $conversationId');
    _socket?.emit('chat.join', {'conversation_id': conversationId});
    currentRoom.value = conversationId;
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    log('📤 Leaving conversation: $conversationId');
    _socket?.emit('chat.leave', {'conversation_id': conversationId});
    if (currentRoom.value == conversationId) {
      currentRoom.value = '';
    }
  }

  /// Send message via v1 API
  void sendMessageV1({
    required String conversationId,
    required String receiverId,
    required String clientMessageId,
    required String content,
    String type = 'text',
    String? replyTo,
    Map<String, dynamic>? attachment,
    Map<String, dynamic>? waterIntakeData,
  }) {
    log('📤 [v1] Sending message to $receiverId');
    _socket?.emit('msg.send', {
      'conversation_id': conversationId,
      'receiver_id': receiverId,
      'client_message_id': clientMessageId,
      'type': type,
      'content': content,
      if (replyTo != null) 'reply_to': replyTo,
      if (attachment != null) 'attachment': attachment,
      if (waterIntakeData != null) 'water_intake_data': waterIntakeData,
    });
  }

  /// Send typing indicator (v1)
  void startTyping({String? conversationId, String? receiverId}) {
    _socket?.emit('typing.start', {
      if (conversationId != null) 'conversation_id': conversationId,
      if (receiverId != null) 'receiver_id': receiverId,
    });
  }

  /// Stop typing indicator (v1)
  void stopTyping({String? conversationId, String? receiverId}) {
    _socket?.emit('typing.stop', {
      if (conversationId != null) 'conversation_id': conversationId,
      if (receiverId != null) 'receiver_id': receiverId,
    });
  }

  /// Mark conversation as read (v1)
  void markConversationRead(String conversationId, int lastReadSeq) {
    _socket?.emit('conv.read', {
      'conversation_id': conversationId,
      'last_read_seq': lastReadSeq,
    });
  }

  // ==========================================
  // Legacy Methods (backward compatibility)
  // ==========================================

  void joinRoom(String conversationId) {
    joinConversation(conversationId);
  }

  void leaveRoom(String conversationId) {
    leaveConversation(conversationId);
  }

  void sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) {
    // Try v1 first
    if (_socket != null && _socket!.connected) {
      sendMessageV1(
        conversationId: conversationId,
        receiverId: receiverId,
        clientMessageId: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        type: messageType,
      );
    }
  }

  void sendTyping(String conversationId) {
    startTyping(conversationId: conversationId);
  }

  void sendStopTyping(String conversationId) {
    stopTyping(conversationId: conversationId);
  }

  void markAsRead(String conversationId) {
    markConversationRead(conversationId, 0);
  }

  void disconnect() {
    if (currentRoom.value.isNotEmpty) {
      leaveConversation(currentRoom.value);
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    log('🔌 Socket disconnected and disposed');
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    _messageController.close();
    _typingController.close();
    _readController.close();
    _mealLogController.close();
    _presenceController.close();
    _customFoodStatusController.close();
    _notificationController.close();
    super.onClose();
  }
}
