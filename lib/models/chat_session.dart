import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType {
  general,
  symptomAnalysis,
  medicationAdvice,
  emergency,
  lifestyle,
}

class ChatSession {
  final String id;
  final String userId;
  final String? title;
  final ChatType chatType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final Map<String, dynamic>? context;

  ChatSession({
    required this.id,
    required this.userId,
    this.title,
    this.chatType = ChatType.general,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'chatType': chatType.toString().split('.').last,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage,
      'context': context ?? {},
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map, String id) {
    return ChatSession(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'],
      chatType: _parseChatType(map['chatType'] ?? 'general'),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'],
      context: map['context'] != null
          ? Map<String, dynamic>.from(map['context'])
          : {},
    );
  }

  static ChatType _parseChatType(String type) {
    switch (type) {
      case 'symptomAnalysis':
        return ChatType.symptomAnalysis;
      case 'medicationAdvice':
        return ChatType.medicationAdvice;
      case 'emergency':
        return ChatType.emergency;
      case 'lifestyle':
        return ChatType.lifestyle;
      default:
        return ChatType.general;
    }
  }

  ChatSession copyWith({
    String? id,
    String? userId,
    String? title,
    ChatType? chatType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    Map<String, dynamic>? context,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      chatType: chatType ?? this.chatType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      context: context ?? this.context,
    );
  }

  String get displayTitle {
    return title ?? _generateTitle();
  }

  String _generateTitle() {
    switch (chatType) {
      case ChatType.symptomAnalysis:
        return 'Symptom Analysis';
      case ChatType.medicationAdvice:
        return 'Medication Advice';
      case ChatType.emergency:
        return 'Emergency Consultation';
      case ChatType.lifestyle:
        return 'Lifestyle Guidance';
      default:
        return 'Health Chat ${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  bool get isRecent => DateTime.now().difference(updatedAt).inHours < 24;

  String? get geminiModel => context?['geminiModel'];
  String? get promptTemplate => context?['promptTemplate'];
}
