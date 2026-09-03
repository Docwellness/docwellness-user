class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final String? attachment;
  final String? description;
  final MessageMetadata? metadata;
  final MessageReplyPreview? replyTo;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  // Set on optimistically-created local messages (see ChatController.
  // sendMessage/sendImageMessage) and echoed back by the backend on both
  // the REST response and the socket `msg.new` payload (chat/models/
  // MessageV1.js's own clientMessageId field) - lets dedup match a
  // socket-delivered echo of a just-sent message against its still-pending
  // optimistic entry even before the REST response has replaced `id` with
  // the real server id (see ChatController's onMessage listener).
  final String? clientMessageId;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    this.attachment,
    this.description,
    this.metadata,
    this.replyTo,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.clientMessageId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Handle attachment which can be String, Map, or null
    String? attachmentUrl;
    if (json['attachment'] != null) {
      if (json['attachment'] is String) {
        attachmentUrl = json['attachment'];
      } else if (json['attachment'] is Map) {
        attachmentUrl = json['attachment']['url'] ?? json['attachment']['path'];
      }
    }

    // Handle messageType which could be 'type' in v1 API
    final typeStr = json['messageType'] ?? json['type'] ?? 'text';

    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      receiverId: json['receiverId'] ?? json['receiver_id'] ?? '',
      content: json['message'] ?? json['content'] ?? '',
      messageType: MessageType.fromString(typeStr),
      attachment: attachmentUrl,
      description: json['description'],
      metadata: json['metadata'] != null
          ? MessageMetadata.fromJson(json['metadata'])
          : json['waterIntakeData'] != null
          ? MessageMetadata.fromJson({
              'waterAmount': json['waterIntakeData']['amount'],
              'amount': json['waterIntakeData']['amount'],
              'source': json['waterIntakeData']['source'],
            })
          : json['customFoodData'] != null
          ? MessageMetadata.fromJson(
              Map<String, dynamic>.from(json['customFoodData']),
            )
          // Live socket delivery (msg.new) puts this under
          // recommendationData rather than nesting it in metadata, unlike
          // the REST/DB shape (Chat.metadata) - handle both.
          : json['recommendationData'] != null
          ? MessageMetadata.fromJson(
              Map<String, dynamic>.from(json['recommendationData']),
            )
          : null,
      replyTo: json['replyTo'] != null && json['replyTo'] is Map
          ? MessageReplyPreview.fromJson(
              Map<String, dynamic>.from(json['replyTo']),
            )
          : null,
      isRead: json['isRead'] ?? json['status'] == 'read' ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      clientMessageId: json['clientMessageId'] ?? json['client_message_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType.value,
      'attachment': attachment,
      'description': description,
      'metadata': metadata?.toJson(),
      'replyTo': replyTo?.toJson(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'clientMessageId': clientMessageId,
    };
  }

  bool get isSentByMe => senderId == _currentUserId;

  static String _currentUserId = '';
  static void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /// Whether `incoming` already exists in `existing` - matches by id OR
  /// clientMessageId (AI_EXECUTION_PLAN.md Phase 6/8, P6-07/P8-02). Pulled
  /// out of ChatController's socket listener as a pure, unit-testable
  /// function - see test/message_dedup_test.dart.
  static bool isDuplicate(List<MessageModel> existing, MessageModel incoming) {
    return existing.any(
      (m) =>
          m.id == incoming.id ||
          (incoming.clientMessageId != null &&
              incoming.clientMessageId!.isNotEmpty &&
              m.clientMessageId == incoming.clientMessageId),
    );
  }
}

// Lightweight quoted-message preview attached to a reply.
// The REST/DB shape (getMessages) keys the id as 'id'; the live socket
// shape (msg.new -> populatedMessage.replyTo, a raw Mongoose doc) keys it
// as '_id' - accept either.
class MessageReplyPreview {
  final String id;
  final String message;
  final String senderId;
  final String messageType;

  MessageReplyPreview({
    required this.id,
    required this.message,
    required this.senderId,
    required this.messageType,
  });

  factory MessageReplyPreview.fromJson(Map<String, dynamic> json) {
    return MessageReplyPreview(
      id: json['id'] ?? json['_id'] ?? '',
      message: json['message'] ?? '',
      senderId: json['senderId'] ?? '',
      messageType: json['messageType'] ?? json['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'senderId': senderId,
      'messageType': messageType,
    };
  }
}

enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  mealLog('meal_log'),
  dietUpdate('diet_update'),
  waterIntake('water_intake'),
  dietPlan('diet_plan'),
  customFood('custom_food'),
  doctorNote('doctor_note'),
  doctorRecommendation('doctor_recommendation'),
  system('system');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

class MessageMetadata {
  final String? mealLogId;
  final String? dietPlanId;
  final String? itemName;
  final int? calories;
  final int? servings;
  final String? servingTime;
  final int? totalConsumed;
  final int? totalPlanned;
  final int? completionPercentage;
  final String? imageUrl;
  final String? action;
  final String? source;
  final int? protein;
  final int? fiber;
  final int? carbs;
  final int? fat;
  final int? weekNumber;
  // Water intake fields
  final int? waterAmount;
  final int? amount;
  // Custom food fields
  final String? foodName;
  final String? description;
  final String? image;
  final String? status;
  final String? customFoodRequestId;
  // Diet plan fields
  final String? dayName;
  final String? weekDay;
  final List<dynamic>? meals;
  final int? totalCalories;
  final int? totalProtein;
  final int? totalCarbs;
  final int? totalFat;
  // Doctor note fields
  final String? noteDate;
  // Doctor recommendation fields
  final String? recommendationText;
  final String? recommendationCategory;

  MessageMetadata({
    this.mealLogId,
    this.dietPlanId,
    this.itemName,
    this.calories,
    this.servings,
    this.servingTime,
    this.totalConsumed,
    this.totalPlanned,
    this.completionPercentage,
    this.imageUrl,
    this.action,
    this.source,
    this.protein,
    this.fiber,
    this.carbs,
    this.fat,
    this.weekNumber,
    this.waterAmount,
    this.amount,
    this.foodName,
    this.description,
    this.image,
    this.status,
    this.customFoodRequestId,
    this.dayName,
    this.weekDay,
    this.meals,
    this.totalCalories,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    this.noteDate,
    this.recommendationText,
    this.recommendationCategory,
  });

  // The backend sends nutrition/percentage numbers as plain JSON numbers,
  // which Dart decodes as `double` whenever the value is fractional (a
  // plan-item plan's macro grams, a completion percentage like 66.7, a
  // ratio-scaled calorie count). A bare `json['x']` assignment into these
  // `int?` fields then throws "type 'double' is not a subtype of type 'int'"
  // - and because that throw escapes ChatService.getMessages' DioException
  // catch, the whole chat screen hangs on its loading spinner. Coerce every
  // numeric field through num first.
  static int? _int(dynamic v) => v is num
      ? v.round()
      : (v is String ? int.tryParse(v) : null);

  factory MessageMetadata.fromJson(Map<String, dynamic> json) {
    return MessageMetadata(
      mealLogId: json['mealLogId'],
      dietPlanId: json['dietPlanId'],
      itemName: json['itemName'],
      calories: _int(json['calories']),
      servings: _int(json['servings']),
      servingTime: json['servingTime'],
      totalConsumed: _int(json['totalConsumed']),
      totalPlanned: _int(json['totalPlanned']),
      completionPercentage: _int(json['completionPercentage']),
      imageUrl: json['imageUrl'],
      action: json['action'],
      source: json['source'],
      protein: _int(json['protein']),
      fiber: _int(json['fiber']),
      carbs: _int(json['carbs']),
      fat: _int(json['fat']),
      weekNumber: _int(json['weekNumber']),
      waterAmount: _int(json['waterAmount']),
      amount: _int(json['amount']),
      foodName: json['foodName'],
      description: json['description'],
      image: json['image'],
      status: json['status'],
      customFoodRequestId: json['customFoodRequestId']?.toString(),
      dayName: json['dayName'],
      weekDay: json['weekDay'],
      meals: json['meals'],
      totalCalories: _int(json['totalCalories']),
      totalProtein: _int(json['totalProtein']),
      totalCarbs: _int(json['totalCarbs']),
      totalFat: _int(json['totalFat']),
      noteDate: json['noteDate'],
      recommendationText: json['recommendationText'],
      // The dietician app's live-socket send path (as opposed to the
      // REST/DB path) nests this under a differently-named 'category' key
      // instead of 'recommendationCategory' - accept either.
      recommendationCategory:
          json['recommendationCategory'] ?? json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealLogId': mealLogId,
      'dietPlanId': dietPlanId,
      'itemName': itemName,
      'calories': calories,
      'servings': servings,
      'servingTime': servingTime,
      'totalConsumed': totalConsumed,
      'totalPlanned': totalPlanned,
      'completionPercentage': completionPercentage,
      'imageUrl': imageUrl,
      'action': action,
      'source': source,
      'protein': protein,
      'fiber': fiber,
      'carbs': carbs,
      'fat': fat,
      'weekNumber': weekNumber,
      'waterAmount': waterAmount,
      'amount': amount,
      'foodName': foodName,
      'description': description,
      'image': image,
      'status': status,
      'customFoodRequestId': customFoodRequestId,
      'dayName': dayName,
      'weekDay': weekDay,
      'meals': meals,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'noteDate': noteDate,
      'recommendationText': recommendationText,
      'recommendationCategory': recommendationCategory,
    };
  }
}
