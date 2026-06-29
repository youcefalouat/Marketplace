import 'dart:async';
import 'dart:convert';

import 'package:signalr_netcore/signalr_client.dart';

import '../models/models.dart';
import 'api_service.dart';

enum ChatRealtimeConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class ChatService {
  final ApiService _apiService = ApiService();
  final Set<int> _joinedConversationIds = <int>{};

  HubConnection? _hubConnection;
  String? _token;
  bool _manualDisconnect = false;

  Function(ChatMessage)? onMessageReceived;
  Function(Conversation)? onConversationUpdated;
  Function(UnreadSummary)? onUnreadCountUpdated;
  Function(MessageReadReceipt)? onMessagesRead;
  Function(int userId, bool isOnline)? onUserPresenceChanged;
  Function(ChatRealtimeConnectionStatus)? onConnectionStatusChanged;
  Future<void> Function()? onReconnected;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> connect(String token) async {
    if (_token != token && _hubConnection != null) {
      await disconnect(resetToken: false);
    }

    _token = token;
    _manualDisconnect = false;

    if (_hubConnection == null) {
      _hubConnection = _buildConnection();
      _registerRealtimeHandlers(_hubConnection!);
    }

    await _ensureConnected();
  }

  HubConnection _buildConnection() {
    final hubUrl = ApiService.baseUrl.replaceFirst('/api', '/chatHub');

    return HubConnectionBuilder()
        .withUrl(
      hubUrl,
      options: HttpConnectionOptions(
        accessTokenFactory: () async => _token ?? '',
        requestTimeout: 10000,
      ),
    )
        .withAutomaticReconnect(
      retryDelays: const [0, 2000, 5000, 10000, 30000],
    ).build();
  }

  void _registerRealtimeHandlers(HubConnection connection) {
    connection.on('ReceiveMessage', _handleIncomingMessage);
    connection.on('ConversationUpdated', _handleConversationUpdated);
    connection.on('UnreadCountUpdated', _handleUnreadCountUpdated);
    connection.on('MessagesRead', _handleMessagesRead);
    connection.on('UserOnline', (args) => _handleUserPresence(args, true));
    connection.on('UserOffline', (args) => _handleUserPresence(args, false));

    connection.onreconnecting(({error}) {
      _emitConnectionStatus(ChatRealtimeConnectionStatus.reconnecting);
    });

    connection.onreconnected(({connectionId}) {
      _emitConnectionStatus(ChatRealtimeConnectionStatus.connected);
      unawaited(_rejoinConversations());
      final callback = onReconnected;
      if (callback != null) {
        unawaited(callback());
      }
    });

    connection.onclose(({error}) {
      if (!_manualDisconnect) {
        _emitConnectionStatus(ChatRealtimeConnectionStatus.disconnected);
      }
    });
  }

  Future<void> _ensureConnected() async {
    final connection = _hubConnection;
    if (connection == null) {
      throw Exception('SignalR n\'est pas configure');
    }

    if (connection.state == HubConnectionState.Connected) {
      _emitConnectionStatus(ChatRealtimeConnectionStatus.connected);
      return;
    }

    if (connection.state == HubConnectionState.Connecting ||
        connection.state == HubConnectionState.Reconnecting) {
      return;
    }

    _emitConnectionStatus(ChatRealtimeConnectionStatus.connecting);
    try {
      await connection.start();
      _emitConnectionStatus(ChatRealtimeConnectionStatus.connected);
      await _rejoinConversations();
    } catch (_) {
      _emitConnectionStatus(ChatRealtimeConnectionStatus.disconnected);
      rethrow;
    }
  }

  Future<void> disconnect({bool resetToken = true}) async {
    _manualDisconnect = true;
    _joinedConversationIds.clear();

    try {
      await _hubConnection?.stop();
    } finally {
      _hubConnection = null;
      if (resetToken) _token = null;
      _emitConnectionStatus(ChatRealtimeConnectionStatus.disconnected);
    }
  }

  Future<void> joinConversation(int conversationId) async {
    if (conversationId <= 0) return;

    _joinedConversationIds.add(conversationId);
    // Only invoke immediately when already connected; _rejoinConversations()
    // handles the join once the hub reconnects.
    if (_hubConnection?.state != HubConnectionState.Connected) return;
    await _hubConnection?.invoke('JoinConversation', args: [conversationId]);
  }

  Future<void> leaveConversation(int conversationId) async {
    if (conversationId <= 0) return;

    _joinedConversationIds.remove(conversationId);
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('LeaveConversation', args: [conversationId]);
    }
  }

  Future<void> _rejoinConversations() async {
    if (_hubConnection?.state != HubConnectionState.Connected) return;

    for (final conversationId in List<int>.from(_joinedConversationIds)) {
      try {
        await _hubConnection
            ?.invoke('JoinConversation', args: [conversationId]);
      } catch (_) {
        // The HTTP refresh after reconnect will repair local state if this fails.
      }
    }
  }

  void _handleIncomingMessage(List<Object?>? args) {
    final data = _decodeFirstArgument(args);
    if (data == null || onMessageReceived == null) return;

    try {
      onMessageReceived!(ChatMessage.fromJson(data));
    } catch (_) {
      // Ignore malformed payloads to keep the chat stream alive.
    }
  }

  void _handleConversationUpdated(List<Object?>? args) {
    final data = _decodeFirstArgument(args);
    if (data == null || onConversationUpdated == null) return;

    try {
      onConversationUpdated!(Conversation.fromJson(data));
    } catch (_) {}
  }

  void _handleUnreadCountUpdated(List<Object?>? args) {
    final data = _decodeFirstArgument(args);
    if (data == null || onUnreadCountUpdated == null) return;

    try {
      onUnreadCountUpdated!(UnreadSummary.fromJson(data));
    } catch (_) {}
  }

  void _handleMessagesRead(List<Object?>? args) {
    final data = _decodeFirstArgument(args);
    if (data == null || onMessagesRead == null) return;

    try {
      onMessagesRead!(MessageReadReceipt.fromJson(data));
    } catch (_) {}
  }

  void _handleUserPresence(List<Object?>? args, bool isOnline) {
    final data = _decodeFirstArgument(args);
    if (data == null || onUserPresenceChanged == null) return;

    final rawUserId = data['userId'];
    final userId = rawUserId is int
        ? rawUserId
        : rawUserId is num
            ? rawUserId.toInt()
            : int.tryParse(rawUserId?.toString() ?? '') ?? 0;
    if (userId > 0) {
      onUserPresenceChanged!(userId, isOnline);
    }
  }

  Map<String, dynamic>? _decodeFirstArgument(List<Object?>? args) {
    if (args == null || args.isEmpty || args.first == null) return null;

    final first = args.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);

    try {
      return jsonDecode(jsonEncode(first)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _emitConnectionStatus(ChatRealtimeConnectionStatus status) {
    onConnectionStatusChanged?.call(status);
  }

  Future<PaginatedResponse<Conversation>> getConversations({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final path = Uri(
      path: '/chat/conversations',
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      },
    ).toString();

    final response = await _apiService.authenticatedRequest(
      path,
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(json, Conversation.fromJson);
    }

    throw Exception('Failed to load conversations: ${response.statusCode}');
  }

  Future<UnreadSummary> getUnreadSummary() async {
    final response = await _apiService.authenticatedRequest(
      '/chat/unread-count',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      return UnreadSummary.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception('Failed to load unread count: ${response.statusCode}');
  }

  Future<List<ChatMessage>> getMessages(
    int conversationId, {
    int pageSize = 50,
    int? beforeMessageId,
  }) async {
    final query = <String, String>{'pageSize': pageSize.toString()};
    if (beforeMessageId != null) {
      query['beforeMessageId'] = beforeMessageId.toString();
    }

    final path = Uri(
      path: '/chat/conversations/$conversationId/messages',
      queryParameters: query,
    ).toString();

    final response = await _apiService.authenticatedRequest(
      path,
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load messages: ${response.statusCode}');
  }

  Future<UnreadSummary> markConversationAsRead(int conversationId) async {
    if (conversationId <= 0) {
      return const UnreadSummary(totalUnread: 0, conversations: []);
    }

    final response = await _apiService.authenticatedRequest(
      '/chat/conversations/$conversationId/read',
      method: 'POST',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return UnreadSummary.fromJson(
        decoded['unreadSummary'] as Map<String, dynamic>,
      );
    }

    throw Exception('Failed to mark messages as read: ${response.statusCode}');
  }

  Future<ChatMessage> sendMessage(
    int conversationId,
    String content, {
    required int annonceId,
    String? clientMessageId,
  }) async {
    final response = await _apiService.authenticatedRequest(
      '/chat/conversations/$conversationId/messages',
      method: 'POST',
      body: {
        'content': content,
        'annonceId': annonceId,
        if (clientMessageId != null) 'clientMessageId': clientMessageId,
      },
    );

    if (response.statusCode == 200) {
      return ChatMessage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    var errorMessage = 'Échec de l\'envoi du message (${response.statusCode})';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = body?['message'] as String?;
      if (msg != null && msg.isNotEmpty) errorMessage = msg;
    } catch (_) {}
    throw Exception(errorMessage);
  }

  Future<Conversation> startConversation(int annonceId) async {
    final response = await _apiService.authenticatedRequest(
      '/chat/start',
      method: 'POST',
      body: {'annonceId': annonceId},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Conversation.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    try {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to start conversation');
    } catch (_) {
      throw Exception('Failed to start conversation: ${response.statusCode}');
    }
  }
}
