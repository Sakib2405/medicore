import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ChatSession> _sessions = [];
  List<ChatMessage> _currentMessages = [];
  String? _currentSessionId;
  bool _isLoading = false;

  List<ChatSession> get sessions => _sessions;
  List<ChatMessage> get currentMessages => _currentMessages;
  String? get currentSessionId => _currentSessionId;
  bool get isLoading => _isLoading;

  Future<String> startChatSession({
    required String userId,
    ChatType chatType = ChatType.general,
    String? title,
    String geminiModel = 'gemini-pro',
    String? promptTemplate,
  }) async {
    try {
      _setLoading(true);

      final sessionData = ChatSession(
        id: '',
        userId: userId,
        title: title,
        chatType: chatType,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        context: {
          'geminiModel': geminiModel,
          if (promptTemplate != null) 'promptTemplate': promptTemplate,
        },
      ).toMap();

      final docRef =
          await _firestore.collection('chat_sessions').add(sessionData);
      _currentSessionId = docRef.id;
      _currentMessages.clear();

      final welcomeMessage = _getWelcomeMessage(chatType);
      final chatMsg = ChatMessage(
        id: 'welcome',
        sessionId: _currentSessionId!,
        content: welcomeMessage,
        isUser: false,
        type: MessageType.text,
        timestamp: DateTime.now(),
        metadata: {
          'model': geminiModel,
          'confidence': 1.0,
        },
      );

      _currentMessages.add(chatMsg);
      await _firestore
          .collection('chat_sessions')
          .doc(_currentSessionId)
          .collection('messages')
          .add(chatMsg.toMap());

      await fetchUserSessions(userId);
      notifyListeners();
      return _currentSessionId!;
    } catch (e) {
      if (kDebugMode) print('Start session error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendMessage(
    String content, {
    bool isUser = true,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentSessionId == null) return;

    try {
      _setLoading(true);
      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: _currentSessionId!,
        content: content,
        isUser: isUser,
        type: type,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      _currentMessages.add(msg);
      notifyListeners();

      await _firestore
          .collection('chat_sessions')
          .doc(_currentSessionId)
          .collection('messages')
          .add(msg.toMap());

      await _firestore
          .collection('chat_sessions')
          .doc(_currentSessionId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage':
            content.length > 50 ? '${content.substring(0, 50)}...' : content,
      });
    } catch (e) {
      if (kDebugMode) print('Send message error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUserSessions(String userId) async {
    try {
      _setLoading(true);
      final snapshot = await _firestore
          .collection('chat_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      _sessions = snapshot.docs
          .map((doc) => ChatSession.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSessionMessages(String sessionId) async {
    try {
      _setLoading(true);
      _currentSessionId = sessionId;
      _currentMessages.clear();

      final snapshot = await _firestore
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      _currentMessages = snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  String _getWelcomeMessage(ChatType chatType) {
    switch (chatType) {
      case ChatType.symptomAnalysis:
        return 'Hello! I\'m here to help analyze your symptoms.';
      case ChatType.medicationAdvice:
        return 'Hello! I can provide medication information.';
      case ChatType.emergency:
        return '⚠️ EMERGENCY MODE: Describe your emergency.';
      case ChatType.lifestyle:
        return 'Hello! I provide lifestyle & wellness advice.';
      default:
        return 'Hello! I\'m your AI health assistant.';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
