class ConversationModel {
  final String id;
  final List<ChatUserModel> participants;
  final String patientId;
  final String doctorId;
  final ChatUserModel? otherUser;
  final LastMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.patientId,
    required this.doctorId,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    // Determine unread count based on user role
    final unreadCountData = json['unreadCount'];
    int unread = 0;
    if (unreadCountData != null) {
      if (unreadCountData is int) {
        unread = unreadCountData;
      } else if (json['patientId'] == currentUserId) {
        unread = unreadCountData['patient'] ?? 0;
      } else {
        unread = unreadCountData['doctor'] ?? 0;
      }
    }

    // Parse participants - can be list of strings or list of objects
    final participantsList = <ChatUserModel>[];
    final participantsData = json['participants'];
    if (participantsData != null) {
      for (final participant in participantsData) {
        if (participant is Map<String, dynamic>) {
          participantsList.add(ChatUserModel.fromJson(participant));
        } else if (participant is String) {
          participantsList.add(
            ChatUserModel(id: participant, name: '', email: '', role: ''),
          );
        }
      }
    }

    // Find the other user (not the current user)
    ChatUserModel? otherUser;
    final otherUserData = json['otherUser'];
    if (otherUserData != null) {
      otherUser = ChatUserModel.fromJson(otherUserData);
    } else {
      // Find other user from participants
      for (final participant in participantsList) {
        if (participant.id != currentUserId) {
          otherUser = participant;
          break;
        }
      }
    }

    final lastMessageData = json['lastMessage'];

    return ConversationModel(
      id: json['_id'] ?? json['id'] ?? '',
      participants: participantsList,
      patientId: json['patientId'] is Map
          ? json['patientId']['_id'] ?? ''
          : json['patientId'] ?? '',
      doctorId: json['doctorId'] is Map
          ? json['doctorId']['_id'] ?? ''
          : json['doctorId'] ?? '',
      otherUser: otherUser,
      lastMessage: lastMessageData != null && lastMessageData is Map
          ? LastMessage.fromJson(Map<String, dynamic>.from(lastMessageData))
          : lastMessageData != null && lastMessageData is String
          ? LastMessage(
              content: lastMessageData,
              timestamp: DateTime.now(),
              senderId: '',
            )
          : null,
      unreadCount: unread,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'patientId': patientId,
      'doctorId': doctorId,
      'otherUser': otherUser?.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get displayName => otherUser?.name ?? 'Unknown';
  String? get displayImage => otherUser?.profileImage;
  bool get isOnline => otherUser?.isOnline ?? false;
}

class LastMessage {
  final String content;
  final DateTime timestamp;
  final String senderId;

  LastMessage({
    required this.content,
    required this.timestamp,
    required this.senderId,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      senderId: json['senderId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }
}

class ChatUserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String role;
  final bool isOnline;

  ChatUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.role,
    this.isOnline = false,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      role: json['role'] ?? 'patient',
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'role': role,
      'isOnline': isOnline,
    };
  }
}
