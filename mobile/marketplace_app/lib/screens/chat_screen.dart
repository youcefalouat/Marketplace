import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../widgets/marketplace_annonce_preview_card.dart';
import 'annonce_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String interlocutorName;
  final int annonceId;
  final String annonceTitle;
  final String annonceImage;
  final double annoncePrice;
  final String annonceCategoryName;
  final String annonceCategoryArName;
  final String annonceStatus;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.interlocutorName,
    required this.annonceId,
    required this.annonceTitle,
    required this.annonceImage,
    required this.annoncePrice,
    required this.annonceCategoryName,
    required this.annonceCategoryArName,
    required this.annonceStatus,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatProvider _chatProvider;
  late int _conversationId;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _chatProvider.addListener(_handleChatUpdates);
    _chatProvider.loadMessages(_conversationId);
  }

  @override
  void dispose() {
    _chatProvider.removeListener(_handleChatUpdates);
    _chatProvider.leaveConversation(_conversationId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleChatUpdates() {
    if (!mounted) return;

    final providerConversationId = _chatProvider.currentConversationId;
    if (providerConversationId != null &&
        providerConversationId > 0 &&
        providerConversationId != _conversationId) {
      setState(() => _conversationId = providerConversationId);
    }

    final messageCount = _chatProvider.currentMessages.length;
    if (messageCount != _lastMessageCount) {
      _lastMessageCount = messageCount;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final sentMessage = await _chatProvider.sendMessage(
      _conversationId,
      content,
      annonceId: widget.annonceId,
    );

    if (sentMessage != null) {
      _messageController.clear();
      if (sentMessage.conversationId != _conversationId && mounted) {
        setState(() => _conversationId = sentMessage.conversationId);
      }
    }
  }

  void _openAnnonceDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnonceDetailScreen(annonceId: widget.annonceId),
      ),
    );
  }

  void _showAnnonceOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l10n.viewDetails),
                onTap: () {
                  Navigator.pop(context);
                  _openAnnonceDetails();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _listingSubtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return widget.annonceStatus.toLowerCase() == 'approved' ||
            widget.annonceStatus.isEmpty
        ? l10n.listingAvailable
        : widget.annonceStatus;
  }

  Color _connectionStatusColor(ChatRealtimeConnectionStatus status) {
    switch (status) {
      case ChatRealtimeConnectionStatus.connected:
        return Colors.greenAccent.shade400;
      case ChatRealtimeConnectionStatus.connecting:
      case ChatRealtimeConnectionStatus.reconnecting:
        return Colors.amberAccent.shade400;
      case ChatRealtimeConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  Conversation? _conversationSnapshot(ChatProvider chatProvider) {
    for (final conversation in chatProvider.conversations) {
      if (_conversationId > 0 && conversation.id == _conversationId) {
        return conversation;
      }
      if (_conversationId <= 0 &&
          conversation.annonceId == widget.annonceId &&
          conversation.interlocutorName == widget.interlocutorName) {
        return conversation;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.interlocutorName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _connectionStatusColor(
                      chatProvider.connectionStatus,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final l10n = AppLocalizations.of(context)!;
          final conversation = _conversationSnapshot(chatProvider);
          final listingPrice = (conversation?.annoncePrice ?? 0) > 0
              ? conversation!.annoncePrice
              : widget.annoncePrice;
          final listingTitle = (conversation?.annonceTitle ?? '').isNotEmpty
              ? conversation!.annonceTitle
              : widget.annonceTitle;
          final listingImage = (conversation?.annonceImage ?? '').isNotEmpty
              ? conversation!.annonceImage
              : widget.annonceImage;
          final listingCategoryName =
              (conversation?.annonceCategoryName ?? '').isNotEmpty
                  ? conversation!.annonceCategoryName
                  : widget.annonceCategoryName;
          final listingCategoryArName =
              (conversation?.annonceCategoryArName ?? '').isNotEmpty
                  ? conversation!.annonceCategoryArName
                  : widget.annonceCategoryArName;
          return SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: MarketplaceAnnoncePreviewCard(
                    annonceId: widget.annonceId,
                    title: listingTitle,
                    imageUrl: listingImage,
                    price: listingPrice,
                    categoryName: listingCategoryName,
                    categoryArName: listingCategoryArName,
                    subtitle: _listingSubtitle(context),
                    onTap: _openAnnonceDetails,
                    onMorePressed: _showAnnonceOptions,
                  ),
                ),
                Expanded(
                  child: chatProvider.isLoading &&
                          chatProvider.currentMessages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : chatProvider.currentMessages.isEmpty
                          ? Center(
                              child: Text(
                                _conversationId > 0
                                    ? l10n.noMessages
                                    : l10n.sendFirstMessage,
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: chatProvider.currentMessages.length,
                              itemBuilder: (context, index) {
                                final message =
                                    chatProvider.currentMessages[index];
                                final isMe = message.isMe;
                                final colors =
                                    Theme.of(context).extension<AppColors>()!;

                                return Align(
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.75,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? colors.primary
                                          : colors.surfaceElevated1,
                                      borderRadius:
                                          BorderRadius.circular(20).copyWith(
                                        bottomRight: isMe
                                            ? const Radius.circular(0)
                                            : const Radius.circular(20),
                                        bottomLeft: !isMe
                                            ? const Radius.circular(0)
                                            : const Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.content,
                                          style: TextStyle(
                                            color: isMe
                                                ? colors.textOnPrimary
                                                : colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              DateFormat('HH:mm').format(
                                                  message.sentAt.toLocal()),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isMe
                                                    ? colors.textOnPrimary
                                                        .withValues(alpha: 0.7)
                                                    : colors.textTertiary,
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                _messageStatusIcon(message),
                                                size: 12,
                                                color: message.deliveryState ==
                                                        MessageDeliveryState
                                                            .failed
                                                    ? colors.error
                                                    : colors.textOnPrimary
                                                        .withValues(alpha: 0.7),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                if (chatProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Text(
                      'Erreur: ${chatProvider.error}',
                      style: TextStyle(
                          color:
                              Theme.of(context).extension<AppColors>()!.error),
                    ),
                  ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<AppColors>()!
                          .surfaceElevated1,
                      border: Border(
                          top: BorderSide(
                              color: Theme.of(context)
                                  .extension<AppColors>()!
                                  .border)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText: l10n.chatMessageHint,
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            color: Theme.of(context).primaryColor,
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _messageStatusIcon(ChatMessage message) {
    switch (message.deliveryState) {
      case MessageDeliveryState.sending:
        return Icons.access_time;
      case MessageDeliveryState.failed:
        return Icons.error_outline;
      case MessageDeliveryState.sent:
        return message.isRead ? Icons.done_all : Icons.done;
    }
  }
}
