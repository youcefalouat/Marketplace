import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<Conversation> _conversations = [];
  List<ChatMessage> _currentMessages = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Conversation> get conversations => _conversations;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void connect(String token) {
    _chatService.connect(token);
    _chatService.onMessageReceived = (message) {
      _currentMessages.add(message);

      // Fix #21: Optimistically update the conversation in-memory
      // instead of reloading all conversations from the server
      final index =
          _conversations.indexWhere((c) => c.id == message.conversationId);
      if (index != -1) {
        final old = _conversations[index];
        _conversations[index] = Conversation(
          id: old.id,
          annonceId: old.annonceId,
          annonceTitle: old.annonceTitle,
          annonceImage: old.annonceImage,
          interlocutorId: old.interlocutorId,
          interlocutorName: old.interlocutorName,
          lastMessageAt: message.sentAt,
          lastMessageContent: message.content,
          hasUnreadMessages: !message.isMe,
          isModeration: old.isModeration,
        );
        // Move updated conversation to the top
        final updated = _conversations.removeAt(index);
        _conversations.insert(0, updated);
      }

      notifyListeners();
    };
  }

  void disconnect() {
    _chatService.disconnect();
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(int conversationId) async {
    _isLoading = true;
    _error = null;
    _currentMessages = []; // Clear previous messages
    notifyListeners();

    try {
      await _chatService.joinConversation(conversationId);
      _currentMessages = await _chatService.getMessages(conversationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(int conversationId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      final sentMessage =
          await _chatService.sendMessage(conversationId, content);

      // Optimistically add the message if it wasn't already added by SignalR
      if (!_currentMessages.any((m) => m.id == sentMessage.id)) {
        _currentMessages.add(sentMessage);
        notifyListeners();
      }

      // We don't necessarily need to reload conversations immediately here
      // as the UI will just display the currentMessages, but we can do it if needed
      // to keep the conversation list snippet up to date.
      loadConversations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Conversation?> startConversation(int annonceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _chatService.startConversation(annonceId);
      if (!_conversations.any((c) => c.id == conversation.id)) {
        _conversations.insert(0, conversation);
      }
      return conversation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void leaveConversation(int conversationId) {
    _chatService.leaveConversation(conversationId);
    _currentMessages = [];
    notifyListeners();
  }
}
