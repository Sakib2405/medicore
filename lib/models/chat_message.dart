import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
  suggestion,
}

class ChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final bool isUser;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.isUser,
    this.type = MessageType.text,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'content': content,
      'isUser': isUser,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata ?? {},
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      sessionId: map['sessionId'] ?? '',
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? true,
      type: _parseMessageType(map['type'] ?? 'text'),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : {},
    );
  }

  static MessageType _parseMessageType(String type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'suggestion':
        return MessageType.suggestion;
      default:
        return MessageType.text;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? content,
    bool? isUser,
    MessageType? type,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  String? get geminiModel => metadata?['model'];
  double? get confidence => metadata?['confidence'];
}
