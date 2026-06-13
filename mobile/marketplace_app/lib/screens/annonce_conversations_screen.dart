import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';

class AnnonceConversationsScreen extends StatefulWidget {
  final int annonceId;
  final String annonceTitle;

  const AnnonceConversationsScreen({
    super.key,
    required this.annonceId,
    required this.annonceTitle,
  });

  @override
  State<AnnonceConversationsScreen> createState() =>
      _AnnonceConversationsScreenState();
}

class _AnnonceConversationsScreenState
    extends State<AnnonceConversationsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Conversation> _conversations = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _page < _totalPages) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 1;
      _conversations = [];
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAnnonceConversations(
        widget.annonceId,
        page: _page,
      );
      setState(() {
        _conversations = response.items;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _page >= _totalPages) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await _apiService.getAnnonceConversations(
        widget.annonceId,
        page: _page + 1,
      );
      setState(() {
        _page++;
        _conversations.addAll(response.items);
        _totalPages = response.totalPages;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Conversations'),
            Text(
              widget.annonceTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColors colors) {
    if (_isLoading && _conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.textTertiary),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _load(refresh: true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: colors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Aucune conversation pour cette annonce',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    final itemCount =
        _conversations.length + (_page < _totalPages ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= _conversations.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildConversationTile(_conversations[index], colors);
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv, AppColors colors) {
    final timeLabel =
        DateFormat('dd/MM HH:mm').format(conv.lastMessageAt.toLocal());

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.primaryMuted,
        backgroundImage: conv.annonceImage.isNotEmpty
            ? CachedNetworkImageProvider(
                ApiService.getImageUrl(conv.annonceImage)!,
              )
            : null,
        child: conv.annonceImage.isEmpty
            ? Icon(Icons.person_outline, color: colors.primary)
            : null,
      ),
      title: Text(
        conv.interlocutorName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight:
              conv.hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  conv.lastMessageContent.isNotEmpty
                      ? conv.lastMessageContent
                      : 'Démarrer la conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: conv.hasUnreadMessages
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: conv.hasUnreadMessages
                        ? colors.textPrimary
                        : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeLabel,
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
              if (conv.unreadCount > 0) ...[
                const SizedBox(width: 6),
                _UnreadBadge(count: conv.unreadCount, colors: colors),
              ],
            ],
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conv.id,
              interlocutorName: conv.interlocutorName,
              interlocutorId: conv.interlocutorId,
              annonceId: conv.annonceId,
              annonceTitle: conv.annonceTitle,
              annonceImage: conv.annonceImage,
              annoncePrice: conv.annoncePrice,
              annonceCategoryName: conv.annonceCategoryName,
              annonceCategoryArName: conv.annonceCategoryArName,
              annonceStatus: conv.annonceStatus,
            ),
          ),
        ).then((_) => _load(refresh: true));
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  final AppColors colors;

  const _UnreadBadge({required this.count, required this.colors});

  @override
  Widget build(BuildContext context) {
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
