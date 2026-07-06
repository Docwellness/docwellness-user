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
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

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
    this.isRead = false,
    this.readAt,
    required this.createdAt,
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
          : null,
      isRead: json['isRead'] ?? json['status'] == 'read' ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
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
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isSentByMe => senderId == _currentUserId;

  static String _currentUserId = '';
  static void setCurrentUserId(String userId) {
    _currentUserId = userId;
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
  });

  factory MessageMetadata.fromJson(Map<String, dynamic> json) {
    return MessageMetadata(
      mealLogId: json['mealLogId'],
      dietPlanId: json['dietPlanId'],
      itemName: json['itemName'],
      calories: json['calories'],
      servings: json['servings'],
      servingTime: json['servingTime'],
      totalConsumed: json['totalConsumed'],
      totalPlanned: json['totalPlanned'],
      completionPercentage: json['completionPercentage'],
      imageUrl: json['imageUrl'],
      action: json['action'],
      source: json['source'],
      protein: json['protein'],
      fiber: json['fiber'],
      carbs: json['carbs'],
      fat: json['fat'],
      weekNumber: json['weekNumber'],
      waterAmount: json['waterAmount'],
      amount: json['amount'],
      foodName: json['foodName'],
      description: json['description'],
      image: json['image'],
      status: json['status'],
      customFoodRequestId: json['customFoodRequestId']?.toString(),
      dayName: json['dayName'],
      weekDay: json['weekDay'],
      meals: json['meals'],
      totalCalories: json['totalCalories'],
      totalProtein: json['totalProtein'],
      totalCarbs: json['totalCarbs'],
      totalFat: json['totalFat'],
      noteDate: json['noteDate'],
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
    };
  }
}
