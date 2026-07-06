import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/app/models/conversation_model.dart';
import 'package:docwellness/app/models/message_model.dart';
import 'package:docwellness/main.dart';

class ChatService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const _conversationPath = '/patient/chat/conversations';
  static const _messagePath = '/patient/chat/message';
  static const _mealNotesPath = '/patient/meal-notes';
  static const _mealStatsPath = '/patient/meal-logs/stats';
  static const _assignedDieticianPath = '/patient/chat/assigned-dietician';
  static const _chatImageUploadPath = '/patient/chat/upload-image';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // Get all conversations for the current user
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _dio.get(
        _conversationPath,
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data
            .map((json) => ConversationModel.fromJson(json, userId ?? ''))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      log('❌ Error fetching conversations: ${e.message}');
      log('Response: ${e.response?.data}');
      return [];
    }
  }

  // Get or create a conversation with a specific user
  Future<ConversationModel?> getOrCreateConversation(
    String participantId,
  ) async {
    try {
      final response = await _dio.post(
        _conversationPath,
        data: {'participantId': participantId},
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ConversationModel.fromJson(
          response.data['data'] ?? response.data,
          userId ?? '',
        );
      }
      return null;
    } on DioException catch (e) {
      log('❌ Error creating conversation: ${e.message}');
      log('Response: ${e.response?.data}');
      return null;
    }
  }

  // Get messages in a conversation
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/patient/chat/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => MessageModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      log('❌ Error fetching messages: ${e.message}');
      log('Response: ${e.response?.data}');
      return [];
    }
  }

  // Send a message via HTTP (fallback if socket fails)
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? replyTo,
  }) async {
    try {
      final response = await _dio.post(
        _messagePath,
        data: {
          'conversationId': conversationId,
          'receiverId': receiverId,
          'message': content,
          'messageType': messageType,
          'metadata': metadata,
          if (replyTo != null) 'replyTo': replyTo,
        },
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageModel.fromJson(response.data['data'] ?? response.data);
      }
      return null;
    } on DioException catch (e) {
      log('❌ Error sending message: ${e.message}');
      log('Response: ${e.response?.data}');
      return null;
    }
  }

  // Mark messages as read
  Future<bool> markAsRead(String conversationId) async {
    try {
      final response = await _dio.post(
        '/patient/chat/conversations/$conversationId/read',
        options: Options(headers: _headers),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      log('❌ Error marking as read: ${e.message}');
      return false;
    }
  }

  // Upload image for chat
  Future<String?> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        _chatImageUploadPath,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['url'] ?? response.data['data']?['url'];
      }
      return null;
    } on DioException catch (e) {
      log('❌ Error uploading image: ${e.message}');
      return null;
    }
  }

  // Get assigned doctor for patient
  Future<ChatUserModel?> getAssignedDoctor() async {
    try {
      final response = await _dio.get(
        _assignedDieticianPath,
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return ChatUserModel.fromJson(response.data['data'] ?? response.data);
      }
      return null;
    } on DioException catch (e) {
      log('❌ Error fetching assigned doctor: ${e.message}');
      return null;
    }
  }

  Future<MessageModel?> sendMealNote({
    required String imagePath,
    required String description,
  }) async {
    try {
      final formDataMap = <String, dynamic>{'description': description};

      if (imagePath.isNotEmpty) {
        formDataMap['image'] = await MultipartFile.fromFile(imagePath);
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(
        _mealNotesPath,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatData =
            response.data['data']?['chatMessage'] ??
            response.data['chatMessage'];
        if (chatData != null) {
          return MessageModel.fromJson(chatData);
        }
      }
      return null;
    } on DioException catch (e) {
      log('❌ Error sending meal note: ${e.message}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTodayMealStats() async {
    try {
      final response = await _dio.get(
        _mealStatsPath,
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      log('❌ Error fetching today meal stats: ${e.message}');
      return null;
    }
  }
}
