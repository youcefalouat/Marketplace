import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import '../models/models.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    // Load conversations when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (authProvider.token != null) {
        chatProvider.connect(authProvider.token!);
        chatProvider.loadConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
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
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: conversation.annonceImage.isNotEmpty
                      ? NetworkImage(
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
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.lastMessageContent.isNotEmpty
                            ? conversation.lastMessageContent
                            : 'Démarrer la conversation',
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversation.id,
                        interlocutorName: conversation.interlocutorName,
                        annonceId: conversation.annonceId,
                        annonceTitle: conversation.annonceTitle,
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
