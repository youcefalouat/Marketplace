import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import '../models/models.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService = ApiService();
  HubConnection? _hubConnection;

  // Callback for receiving messages
  Function(ChatMessage)? onMessageReceived;

  Future<void> connect(String token) async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    final hubUrl = ApiService.baseUrl.replaceFirst('/api', '/chatHub');

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on('ReceiveMessage', _handleIncomingMessage);

    try {
      await _hubConnection?.start();
      print('SignalR Connected');
    } catch (e) {
      print('Error connecting to SignalR: $e');
    }
  }

  void _handleIncomingMessage(List<Object?>? args) {
    if (args != null && args.isNotEmpty && onMessageReceived != null) {
      final messageData = args[0] as Map<String, dynamic>;
      // Need to handle the fact that signalr might return a Map<dynamic, dynamic>
      // or cast it properly
      try {
        // Convert Map<dynamic, dynamic> to Map<String, dynamic> if necessary
        final json = jsonDecode(jsonEncode(messageData));
        final message = ChatMessage.fromJson(json);
        onMessageReceived!(message);
      } catch (e) {
        print('Error parsing incoming message: $e');
      }
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
  }

  Future<void> joinConversation(int conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('JoinConversation', args: [conversationId]);
    }
  }

  Future<void> leaveConversation(int conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('LeaveConversation', args: [conversationId]);
    }
  }

  // API Methods
  Future<List<Conversation>> getConversations() async {
    final response = await _apiService.authenticatedRequest(
      '/chat/conversations',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load conversations: ${response.statusCode}');
    }
  }

  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final response = await _apiService.authenticatedRequest(
      '/chat/conversations/$conversationId/messages',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  Future<ChatMessage> sendMessage(int conversationId, String content) async {
    final response = await _apiService.authenticatedRequest(
      '/chat/conversations/$conversationId/messages',
      method: 'POST',
      body: {'content': content},
    );

    if (response.statusCode == 200) {
      return ChatMessage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  Future<Conversation> startConversation(int annonceId) async {
    final response = await _apiService.authenticatedRequest(
      '/chat/start',
      method: 'POST',
      body: {'annonceId': annonceId},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      // Decode error message if possible
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to start conversation');
      } catch (_) {
        throw Exception('Failed to start conversation: ${response.statusCode}');
      }
    }
  }
}
