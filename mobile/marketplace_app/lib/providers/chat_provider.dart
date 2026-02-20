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

      // Update conversation last message if it exists in list
      final index =
          _conversations.indexWhere((c) => c.id == message.conversationId);
      if (index != -1) {
        // We can't update immutable Conversation object, maybe just reload conversations or create a copy
        // For now, simpler to reload or just notify
        loadConversations();
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
      // Optimistic update? Or wait for server?
      // Wait for server to be safe
      await _chatService.sendMessage(conversationId, content);
      // The message will be added via onMessageReceived if we are connected and subscribed
      // OR we can add it manually here if we want instant feedback
      // But since we are sender, onMessageReceived might trigger for us too depending on backend
      // Backend broadcasts to group, so we might receive it back.
      // If backend sends back to group, let's rely on that or handle duplication.
      // My backend implementation sends to "Others" or "All"?
      // `_hubContext.Clients.Group(id.ToString()).SendAsync("ReceiveMessage", messageDto);`
      // This sends to EVERYONE in the group, including sender if they are in the group.
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
