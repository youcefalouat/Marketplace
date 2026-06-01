import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import '../l10n/app_localizations.dart';
import '../l10n/category_localizations.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadConversations(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<ChatProvider>(context, listen: false)
          .loadMoreConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.messages),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final colors = Theme.of(context).extension<AppColors>()!;

        if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatProvider.error != null && chatProvider.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Erreur: ${chatProvider.error}'),
                ElevatedButton(
                  onPressed: () =>
                      chatProvider.loadConversations(refresh: true),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (chatProvider.conversations.isEmpty) {
          return const Center(child: Text('Aucune conversation'));
        }

        final itemCount = chatProvider.conversations.length +
            (chatProvider.hasMoreConversations ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () =>
              chatProvider.loadConversations(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= chatProvider.conversations.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final conversation = chatProvider.conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: conversation.annonceImage.isNotEmpty
                      ? CachedNetworkImageProvider(
                          ApiService.getImageUrl(conversation.annonceImage)!)
                      : null,
                  child: conversation.annonceImage.isEmpty
                      ? const Icon(Icons.shopping_bag)
                      : null,
                ),
                title: Text(
                  conversation.interlocutorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: conversation.hasUnreadMessages
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      [
                        AppLocalizations.of(context)!.price(
                          conversation.annoncePrice.toStringAsFixed(0),
                        ),
                        localizedCategoryText(
                          context,
                          conversation.annonceCategoryName,
                          arName: conversation.annonceCategoryArName,
                        ),
                      ].where((value) => value.isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessageContent.isNotEmpty
                                ? conversation.lastMessageContent
                                : AppLocalizations.of(context)!
                                    .startConversation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: conversation.hasUnreadMessages
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM HH:mm')
                              .format(conversation.lastMessageAt.toLocal()),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textTertiary,
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(count: conversation.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  if (conversation.unreadCount > 0) {
                    chatProvider.markConversationRead(conversation.id);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversation.id,
                        interlocutorName: conversation.interlocutorName,
                        annonceId: conversation.annonceId,
                        annonceTitle: conversation.annonceTitle,
                        annonceImage: conversation.annonceImage,
                        annoncePrice: conversation.annoncePrice,
                        annonceCategoryName: conversation.annonceCategoryName,
                        annonceCategoryArName:
                            conversation.annonceCategoryArName,
                        annonceStatus: conversation.annonceStatus,
                      ),
                    ),
                  ).then((_) {
                    chatProvider.loadConversations(refresh: true);
                  });
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final label = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: colors.textOnPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
