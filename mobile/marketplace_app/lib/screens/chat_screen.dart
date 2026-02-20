import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import 'annonce_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String interlocutorName;
  final int annonceId;
  final String annonceTitle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.interlocutorName,
    required this.annonceId,
    required this.annonceTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadMessages(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Consider if we should "leave" the conversation in SignalR
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      Provider.of<ChatProvider>(context, listen: false)
          .sendMessage(widget.conversationId, content);
      _messageController.clear();
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.interlocutorName, style: const TextStyle(fontSize: 16)),
            GestureDetector(
              onTap: () {
                // Navigate to AnnonceDetailScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AnnonceDetailScreen(annonceId: widget.annonceId),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    widget.annonceTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.currentMessages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Trigger scroll to bottom when messages change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Only scroll if we are already near bottom or it's initial load?
            // For now, let's try to keep at bottom
            _scrollToBottom();
          });

          return Column(
            children: [
              Expanded(
                child: chatProvider.currentMessages.isEmpty
                    ? const Center(child: Text('Aucun message'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatProvider.currentMessages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.currentMessages[index];
                          final isMe = message.isMe;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[200],
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
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color:
                                          isMe ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm')
                                        .format(message.sentAt.toLocal()),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
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
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Erreur: ${chatProvider.error}',
                      style: const TextStyle(color: Colors.red)),
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Votre message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
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
            ],
          );
        },
      ),
    );
  }
}
