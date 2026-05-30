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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.messages), //Text('messages'),
      ),
      body: _buildChatsTab(),
    );
  }

  Widget _buildChatsTab() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
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
                  onPressed: chatProvider.loadConversations,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (chatProvider.conversations.isEmpty) {
          return const Center(
            child: Text('Aucune conversation'),
          );
        }

        return RefreshIndicator(
          onRefresh: chatProvider.loadConversations,
          child: ListView.builder(
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              final colors = Theme.of(context).extension<AppColors>()!;
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
                    chatProvider.loadConversations();
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
