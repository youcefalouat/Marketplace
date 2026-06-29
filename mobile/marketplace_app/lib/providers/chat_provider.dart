import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final Set<int> _markingReadConversationIds = <int>{};
  static const Duration _chatRequestTimeout = Duration(seconds: 12);

  List<Conversation> _conversations = [];
  List<ChatMessage> _currentMessages = [];
  Map<int, int> _conversationUnreadCounts = {};
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  int _messageLoadGeneration = 0;
  String? _error;
  String? _connectedToken;
  int? _currentUserId;
  int? _currentConversationId;
  int _totalUnreadCount = 0;
  ChatRealtimeConnectionStatus _connectionStatus =
      ChatRealtimeConnectionStatus.disconnected;
  bool _isForeground = true;

  // Conversation list pagination
  int _conversationsPage = 1;
  int _conversationsTotalPages = 1;
  bool _isLoadingMoreConversations = false;

  // Search
  String _searchQuery = '';

  List<Conversation> get conversations => _conversations;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;
  int? get currentConversationId => _currentConversationId;
  int get totalUnreadCount => _totalUnreadCount;
  Map<int, int> get conversationUnreadCounts =>
      Map.unmodifiable(_conversationUnreadCounts);
  ChatRealtimeConnectionStatus get connectionStatus => _connectionStatus;
  bool get isRealtimeConnected =>
      _connectionStatus == ChatRealtimeConnectionStatus.connected;
  bool get hasMoreConversations =>
      _conversationsPage < _conversationsTotalPages;
  bool get isLoadingMoreConversations => _isLoadingMoreConversations;

  String get searchQuery => _searchQuery;

  /// Returns conversations filtered by the current search query.
  /// Matching is case- and accent-insensitive across interlocutor name and annonce title.
  List<Conversation> get filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    final q = _normalize(_searchQuery);
    return _conversations.where((c) {
      return _normalize(c.interlocutorName).contains(q) ||
          _normalize(c.annonceTitle).contains(q);
    }).toList();
  }

  void setAuthToken(String? token) {
    setAuthSession(token: token, userId: _currentUserId);
  }

  void setAuthSession({required String? token, required int? userId}) {
    if (token == _connectedToken && userId == _currentUserId) return;

    _connectedToken = token;
    _currentUserId = userId;

    if (token == null || token.isEmpty) {
      _clearLocalState();
      unawaited(_chatService.disconnect());
      notifyListeners();
      return;
    }

    unawaited(connect(token));
  }

  Future<void> connect(String token) async {
    _wireRealtimeCallbacks();

    try {
      await _chatService.connect(token);
      await loadUnreadCount();
      if (_conversations.isNotEmpty) {
        unawaited(loadConversations(showLoader: false));
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _connectedToken = null;
    _currentUserId = null;
    _clearLocalState();
    await _chatService.disconnect();
    notifyListeners();
  }

  void _clearLocalState() {
    _currentConversationId = null;
    _currentMessages = [];
    _conversations = [];
    _conversationUnreadCounts = {};
    _isLoading = false;
    _isLoadingMessages = false;
    _messageLoadGeneration++;
    _totalUnreadCount = 0;
    _error = null;
    _connectionStatus = ChatRealtimeConnectionStatus.disconnected;
    _searchQuery = '';
  }

  void _wireRealtimeCallbacks() {
    _chatService.onMessageReceived = _handleIncomingMessage;
    _chatService.onConversationUpdated = _handleConversationUpdated;
    _chatService.onUnreadCountUpdated = _handleUnreadCountUpdated;
    _chatService.onMessagesRead = _handleMessagesRead;
    _chatService.onUserPresenceChanged = _handleUserPresenceChanged;
    _chatService.onConnectionStatusChanged = _handleConnectionStatusChanged;
    _chatService.onReconnected = _handleRealtimeRecovered;
  }

  Future<void> _handleRealtimeRecovered() async {
    await loadUnreadCount();
    await loadConversations(showLoader: false);

    final currentId = _currentConversationId;
    if (currentId != null && currentId > 0) {
      await loadMessages(currentId, showLoader: false);
    }
  }

  void _handleConnectionStatusChanged(ChatRealtimeConnectionStatus status) {
    if (_connectionStatus == status) return;
    _connectionStatus = status;
    notifyListeners();
  }

  /// Called from the app's lifecycle observer. A conversation is only
  /// considered "actively viewed" — and therefore safe to auto-mark-read —
  /// when the app is actually in the foreground. A backgrounded app still
  /// has its ChatScreen mounted (Flutter doesn't dispose paused routes),
  /// so without this gate, messages received while the app sits in the
  /// background would be marked read before the user ever sees them.
  void setForeground(bool value) {
    if (_isForeground == value) return;
    _isForeground = value;

    if (value) {
      final currentId = _currentConversationId;
      if (currentId != null && currentId > 0) {
        unawaited(markConversationRead(currentId));
      }
    }
  }

  /// Whether [conversationId] is the one currently open on screen — i.e.
  /// safe to treat its incoming messages as already seen by the user.
  bool _isActivelyViewing(int conversationId) =>
      _isForeground && _currentConversationId == conversationId;

  void _handleIncomingMessage(ChatMessage message) {
    // Still insert into the loaded list (if applicable) so the message is
    // visible immediately once the user looks at the screen again — this is
    // independent of whether it should be auto-marked as read right now.
    _insertOrReplaceCurrentMessage(message);
    final isCurrentConversation = _isActivelyViewing(message.conversationId);

    _touchConversationWithMessage(message);

    if (!message.isMe && !isCurrentConversation) {
      _incrementUnreadLocally(message.conversationId);
    }

    if (!message.isMe && isCurrentConversation) {
      _markConversationReadLocally(message.conversationId);
      unawaited(markConversationRead(message.conversationId));
    }

    notifyListeners();
  }

  bool _insertOrReplaceCurrentMessage(ChatMessage message) {
    final index = _currentMessages.indexWhere((existing) {
      final sameServerId = existing.id > 0 && existing.id == message.id;
      final sameClientId = message.clientMessageId != null &&
          existing.clientMessageId == message.clientMessageId;
      return sameServerId || sameClientId;
    });

    if (index != -1) {
      final existing = _currentMessages[index];
      final shouldAdoptConversationId =
          (_currentConversationId == null || _currentConversationId! <= 0) &&
              message.conversationId > 0;

      if (shouldAdoptConversationId) {
        _currentConversationId = message.conversationId;
        unawaited(_chatService.joinConversation(message.conversationId));
      }

      _currentMessages[index] = message.copyWith(
        clientMessageId: existing.clientMessageId ?? message.clientMessageId,
        deliveryState: MessageDeliveryState.sent,
      );
      _sortCurrentMessages();
      return true;
    }

    if (_currentConversationId == message.conversationId) {
      _currentMessages.add(message);
      _sortCurrentMessages();
      return true;
    }

    return false;
  }

  void _handleConversationUpdated(Conversation conversation) {
    final shouldRead =
        _isActivelyViewing(conversation.id) && conversation.unreadCount > 0;
    final effectiveConversation = shouldRead
        ? conversation.copyWith(unreadCount: 0, hasUnreadMessages: false)
        : conversation;

    _upsertConversation(effectiveConversation);

    if (shouldRead) {
      unawaited(markConversationRead(conversation.id));
    }

    notifyListeners();
  }

  void _handleUnreadCountUpdated(UnreadSummary summary) {
    _applyUnreadSummary(summary);
    notifyListeners();
  }

  void _handleMessagesRead(MessageReadReceipt receipt) {
    final ids = receipt.messageIds.toSet();
    var changed = false;

    _currentMessages = _currentMessages.map((message) {
      if (message.conversationId == receipt.conversationId &&
          message.isMe &&
          ids.contains(message.id) &&
          !message.isRead) {
        changed = true;
        return message.copyWith(isRead: true, readAt: receipt.readAt);
      }
      return message;
    }).toList();

    if (changed) notifyListeners();
  }

  void _handleUserPresenceChanged(int userId, bool isOnline) {
    var changed = false;
    _conversations = _conversations.map((conversation) {
      if (conversation.interlocutorId == userId &&
          conversation.isInterlocutorOnline != isOnline) {
        changed = true;
        return conversation.copyWith(isInterlocutorOnline: isOnline);
      }
      return conversation;
    }).toList();

    if (changed) notifyListeners();
  }

  Future<void> loadConversations({
    bool showLoader = true,
    bool refresh = false,
  }) async {
    if (refresh) {
      _conversationsPage = 1;
      _conversations = [];
    }

    if (showLoader) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _chatService.getConversations(
        page: _conversationsPage,
      );

      if (refresh || _conversationsPage == 1) {
        _conversations = response.items;
      } else {
        for (final conv in response.items) {
          _upsertConversation(conv);
        }
      }

      _conversationsTotalPages = response.totalPages;
      _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

      _conversationUnreadCounts = {
        for (final conversation in _conversations)
          if (conversation.unreadCount > 0)
            conversation.id: conversation.unreadCount,
      };
      _totalUnreadCount = _conversationUnreadCounts.values.fold<int>(
        0,
        (total, count) => total + count,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (showLoader) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadMoreConversations() async {
    if (!hasMoreConversations || _isLoadingMoreConversations) return;

    _isLoadingMoreConversations = true;
    _conversationsPage++;
    notifyListeners();

    try {
      final response = await _chatService.getConversations(
        page: _conversationsPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      for (final conv in response.items) {
        _upsertConversation(conv);
      }

      _conversationsTotalPages = response.totalPages;
      _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    } catch (e) {
      _conversationsPage--;
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingMoreConversations = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final summary = await _chatService.getUnreadSummary();
      _applyUnreadSummary(summary);
      notifyListeners();
    } catch (_) {
      // Keep the existing badge until the next successful sync.
    }
  }

  Future<void> loadMessages(
    int conversationId, {
    bool showLoader = true,
  }) async {
    final loadGeneration =
        showLoader ? ++_messageLoadGeneration : _messageLoadGeneration;
    if (showLoader) {
      _isLoadingMessages = true;
      _error = null;
      _currentMessages = [];
    }
    _currentConversationId = conversationId;
    notifyListeners();

    if (conversationId <= 0) {
      _isLoadingMessages = false;
      notifyListeners();
      return;
    }

    try {
      if (showLoader) {
        // Don't rely on the app-lifecycle observer alone to flush stale
        // sockets — some OEM battery managers delay or skip lifecycle
        // callbacks. Opening a chat is the exact moment a hang is visible
        // to the user, so always start it with a guaranteed-fresh connection.
        ApiService().flushHttpClient();
      }
      // Don't block HTTP message loading on SignalR — join fires in background
      // and _rejoinConversations() will retry if the hub isn't ready yet.
      unawaited(_chatService.joinConversation(conversationId));
      final messages = await _chatService
          .getMessages(conversationId)
          .timeout(_chatRequestTimeout);
      if (loadGeneration != _messageLoadGeneration ||
          _currentConversationId != conversationId) {
        return;
      }
      _currentMessages = messages;
      _sortCurrentMessages();
      _markConversationReadLocally(conversationId);
      unawaited(markConversationRead(conversationId));
    } catch (e) {
      if (loadGeneration != _messageLoadGeneration ||
          _currentConversationId != conversationId) {
        return;
      }
      _error = e is TimeoutException
          ? 'Connexion lente. Vérifiez votre réseau et réessayez.'
          : e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (loadGeneration == _messageLoadGeneration &&
          _currentConversationId == conversationId) {
        _isLoadingMessages = false;
      }
      notifyListeners();
    }
  }

  Future<void> markConversationRead(int conversationId) async {
    if (conversationId <= 0 ||
        !_markingReadConversationIds.add(conversationId)) {
      return;
    }

    _markConversationReadLocally(conversationId);
    notifyListeners();

    try {
      final summary = await _chatService.markConversationAsRead(conversationId);
      _applyUnreadSummary(summary);
    } catch (_) {
      // The next reconnect/list refresh will resync unread counts.
    } finally {
      _markingReadConversationIds.remove(conversationId);
      notifyListeners();
    }
  }

  Future<ChatMessage?> sendMessage(
    int conversationId,
    String content, {
    required int annonceId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    final clientMessageId =
        'm_${DateTime.now().microsecondsSinceEpoch}_${_currentUserId ?? 0}';
    final tempMessage = ChatMessage(
      id: -DateTime.now().microsecondsSinceEpoch,
      conversationId: conversationId,
      senderId: _currentUserId ?? 0,
      content: trimmed,
      sentAt: DateTime.now().toUtc(),
      isRead: false,
      isMe: true,
      clientMessageId: clientMessageId,
      deliveryState: MessageDeliveryState.sending,
    );

    _currentMessages.add(tempMessage);
    _sortCurrentMessages();
    _touchConversationWithMessage(tempMessage);
    notifyListeners();

    try {
      final sentMessage = await _chatService.sendMessage(
        conversationId,
        trimmed,
        annonceId: annonceId,
        clientMessageId: clientMessageId,
      );

      final normalizedMessage = sentMessage.copyWith(
        clientMessageId: clientMessageId,
        deliveryState: MessageDeliveryState.sent,
      );

      if (_currentConversationId == null || _currentConversationId! <= 0) {
        _currentConversationId = normalizedMessage.conversationId;
        unawaited(
            _chatService.joinConversation(normalizedMessage.conversationId));
      }

      _replaceOptimisticMessage(clientMessageId, normalizedMessage);
      _touchConversationWithMessage(normalizedMessage);
      notifyListeners();

      return normalizedMessage;
    } catch (e) {
      _markOptimisticMessageFailed(clientMessageId);
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<Conversation?> startConversation(int annonceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      ApiService().flushHttpClient();
      final conversation = await _chatService
          .startConversation(annonceId)
          .timeout(_chatRequestTimeout);
      if (!conversation.isPending) {
        _upsertConversation(conversation);
      }
      return conversation;
    } catch (e) {
      _error = e is TimeoutException
          ? 'Connexion lente. Vérifiez votre réseau et réessayez.'
          : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void leaveConversation(int conversationId) {
    if (conversationId > 0) {
      unawaited(_chatService.leaveConversation(conversationId));
    }

    // Multiple ChatScreens can be stacked in the navigator at once (e.g.
    // "Contacter" pushes a new screen without popping the previous one).
    // Only the screen that owns the *currently active* conversation is
    // allowed to clear shared state on dispose — otherwise closing an old,
    // already-superseded screen would wipe out messages/loading state for
    // whichever conversation is actually on screen now.
    if (_currentConversationId != conversationId) {
      return;
    }

    _currentConversationId = null;
    _messageLoadGeneration++;
    _isLoadingMessages = false;
    _currentMessages = [];
    notifyListeners();
  }

  void _replaceOptimisticMessage(String clientMessageId, ChatMessage message) {
    final index = _currentMessages.indexWhere(
      (existing) => existing.clientMessageId == clientMessageId,
    );
    if (index == -1) {
      _currentMessages.add(message);
    } else {
      _currentMessages[index] = message;
    }
    _sortCurrentMessages();
  }

  void _markOptimisticMessageFailed(String clientMessageId) {
    _currentMessages = _currentMessages.map((message) {
      if (message.clientMessageId == clientMessageId) {
        return message.copyWith(deliveryState: MessageDeliveryState.failed);
      }
      return message;
    }).toList();
  }

  void _touchConversationWithMessage(ChatMessage message) {
    if (message.conversationId <= 0) return;

    final index =
        _conversations.indexWhere((c) => c.id == message.conversationId);
    if (index == -1) {
      unawaited(loadConversations(showLoader: false));
      return;
    }

    final old = _conversations[index];
    final unreadCount =
        _conversationUnreadCounts[message.conversationId] ?? old.unreadCount;
    final updated = old.copyWith(
      lastMessageAt: message.sentAt,
      lastMessageContent: message.content,
      lastMessageSenderId: message.senderId,
      unreadCount: unreadCount,
      hasUnreadMessages: unreadCount > 0,
    );

    _conversations[index] = updated;
    _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  void _upsertConversation(Conversation conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index == -1) {
      _conversations.insert(0, conversation);
    } else {
      _conversations[index] = conversation;
    }

    if (conversation.unreadCount > 0) {
      _conversationUnreadCounts[conversation.id] = conversation.unreadCount;
    } else {
      _conversationUnreadCounts.remove(conversation.id);
    }

    _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  void _incrementUnreadLocally(int conversationId) {
    if (conversationId <= 0) return;

    final nextCount = (_conversationUnreadCounts[conversationId] ?? 0) + 1;
    _conversationUnreadCounts[conversationId] = nextCount;
    _totalUnreadCount += 1;

    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        unreadCount: nextCount,
        hasUnreadMessages: true,
      );
    }
  }

  void _markConversationReadLocally(int conversationId) {
    if (conversationId <= 0) return;

    final previousCount = _conversationUnreadCounts.remove(conversationId) ?? 0;
    if (previousCount > 0) {
      final nextTotal = _totalUnreadCount - previousCount;
      _totalUnreadCount = nextTotal < 0 ? 0 : nextTotal;
    }

    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        unreadCount: 0,
        hasUnreadMessages: false,
      );
    }
  }

  void _applyUnreadSummary(UnreadSummary summary) {
    _totalUnreadCount = summary.totalUnread;
    _conversationUnreadCounts = summary.perConversation;

    _conversations = _conversations.map((conversation) {
      final count = _conversationUnreadCounts[conversation.id] ?? 0;
      return conversation.copyWith(
        unreadCount: count,
        hasUnreadMessages: count > 0,
      );
    }).toList();
  }

  /// Updates the active search query and triggers a server-side refresh.
  /// The debounce (300 ms) lives in the screen; this method applies instantly.
  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (trimmed == _searchQuery) return;
    _searchQuery = trimmed;
    notifyListeners(); // local filter via filteredConversations kicks in immediately

    if (trimmed.isEmpty) {
      unawaited(loadConversations(refresh: true, showLoader: false));
    } else {
      unawaited(_searchConversations(trimmed));
    }
  }

  /// Refreshes the conversation list while honouring the active search query.
  /// Use this instead of [loadConversations] when navigating back to the screen.
  Future<void> refreshConversations() async {
    if (_searchQuery.isNotEmpty) {
      await _searchConversations(_searchQuery);
    } else {
      await loadConversations(refresh: true);
    }
  }

  Future<void> _searchConversations(String query) async {
    try {
      final response = await _chatService.getConversations(
        page: 1,
        search: query,
      );
      // Discard stale response if the query changed while the request was in flight.
      if (_searchQuery != query) return;
      _conversations = response.items;
      _conversationsTotalPages = response.totalPages;
      _conversationsPage = 1;
      _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      notifyListeners();
    } catch (_) {
      // The local filter from filteredConversations stays active on network error.
    }
  }

  /// Strips accents and lowercases [s] for accent-insensitive comparison.
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  void _sortCurrentMessages() {
    _currentMessages.sort((a, b) {
      final byTime = a.sentAt.compareTo(b.sentAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
  }
}
