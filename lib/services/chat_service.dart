import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> startChatSession({
    required String userId,
    ChatType chatType = ChatType.general,
    String? title,
    String geminiModel = 'gemini-pro',
    String? promptTemplate,
  }) async {
    try {
      final now = DateTime.now();
      final session = ChatSession(
        id: '',
        userId: userId,
        chatType: chatType,
        title: title,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        context: {
          'geminiModel': geminiModel,
          if (promptTemplate != null) 'promptTemplate': promptTemplate,
        },
      );

      final docRef =
          await _firestore.collection('chat_sessions').add(session.toMap());

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendMessage(String sessionId, ChatMessage message) async {
    try {
      await _firestore
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .add(message.toMap());

      await _firestore.collection('chat_sessions').doc(sessionId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': message.content.length > 50
            ? '${message.content.substring(0, 50)}...'
            : message.content,
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ChatMessage>> getChatMessages(String sessionId) {
    return _firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ChatSession>> getUserChatSessions(String userId) {
    return _firestore
        .collection('chat_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSession.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> closeChatSession(String sessionId) async {
    try {
      await _firestore.collection('chat_sessions').doc(sessionId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
