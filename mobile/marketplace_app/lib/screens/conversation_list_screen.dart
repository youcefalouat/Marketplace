import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/category_localizations.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_states.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      // Restore the preserved search query into the text field.
      _searchController.text = chatProvider.searchQuery;
      chatProvider.refreshConversations();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<ChatProvider>(context, listen: false).loadMoreConversations();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      Provider.of<ChatProvider>(context, listen: false).setSearchQuery(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    Provider.of<ChatProvider>(context, listen: false).setSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.messages),
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Search bar pinned above the scroll view.
  /// Uses [ValueListenableBuilder] so only the bar rebuilds on each keystroke —
  /// the conversation list stays untouched until the 300 ms debounce fires.
  Widget _buildSearchBar(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPadding,
        AppLayout.spacing8,
        AppLayout.screenPadding,
        AppLayout.spacing4,
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (context, value, _) {
          return TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.conversationSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: AppLocalizations.of(context)!.cancel,
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: AppLayout.borderRadiusMedium,
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colors.surface,
              contentPadding: EdgeInsets.zero,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final l10n = AppLocalizations.of(context)!;

        // Initial skeleton loading
        if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
          return _buildSkeletonList();
        }

        if (chatProvider.error != null && chatProvider.conversations.isEmpty) {
          return AppErrorState(
            message: chatProvider.error!,
            onRetry: () => chatProvider.loadConversations(refresh: true),
            retryLabel: l10n.retry,
          );
        }

        final conversations = chatProvider.filteredConversations;

        if (conversations.isEmpty && chatProvider.searchQuery.isNotEmpty) {
          return AppEmptyState(
            icon: Icons.search_off_rounded,
            title: l10n.noConversationsFound,
            subtitle: l10n.noConversationsFoundHint,
          );
        }

        if (conversations.isEmpty) {
          return AppEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: l10n.messages,
            subtitle: l10n.startConversation,
          );
        }

        final itemCount =
            conversations.length + (chatProvider.hasMoreConversations ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () => chatProvider.refreshConversations(),
          child: ListView.separated(
            controller: _scrollController,
            itemCount: itemCount,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: AppLayout.screenPadding +
                  56 +
                  AppLayout.spacing12, // align under content
              endIndent: 0,
              color: Theme.of(context).extension<AppColors>()!.borderSubtle,
            ),
            itemBuilder: (context, index) {
              if (index >= conversations.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppLayout.spacing16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final conversation = conversations[index];
              return _ConversationTile(
                conversation: conversation,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversation.id,
                        interlocutorName: conversation.interlocutorName,
                        interlocutorId: conversation.interlocutorId,
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
                    // refreshConversations respects any active search query.
                    chatProvider.refreshConversations();
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
      itemBuilder: (_, __) => const _ConversationSkeleton(),
    );
  }
}

// ─────────────────────────────────────────────────────
// Conversation tile
// ─────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final dynamic conversation; // Conversation from ChatProvider
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final hasUnread = conversation.hasUnreadMessages as bool;

    final imageUrl = (conversation.annonceImage as String).isNotEmpty
        ? ApiService.getImageUrl(conversation.annonceImage as String)
        : null;

    final categoryLabel = localizedCategoryText(
      context,
      conversation.annonceCategoryName as String,
      arName: conversation.annonceCategoryArName as String,
    );
    final priceText =
        l10n.price((conversation.annoncePrice as double).toStringAsFixed(0));
    final metaLine =
        [priceText, categoryLabel].where((s) => s.isNotEmpty).join(' • ');

    final lastMsg = (conversation.lastMessageContent as String).isNotEmpty
        ? conversation.lastMessageContent as String
        : l10n.startConversation;

    return Material(
      color: hasUnread ? colors.surfaceHighlight : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.screenPadding,
            vertical: AppLayout.spacing12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Listing thumbnail
              ClipRRect(
                borderRadius: AppLayout.borderRadiusMedium,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: colors.imagePlaceholder,
                          ),
                          errorWidget: (_, __, ___) =>
                              _ListingImageFallback(colors: colors),
                        )
                      : _ListingImageFallback(colors: colors),
                ),
              ),
              const SizedBox(width: AppLayout.spacing12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + timestamp
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            conversation.interlocutorName as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppLayout.spacing8),
                        Text(
                          _formatRelativeTime(
                              conversation.lastMessageAt as DateTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? colors.primary
                                : colors.textTertiary,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    // Price • category
                    if (metaLine.isNotEmpty) ...[
                      const SizedBox(height: AppLayout.spacing4),
                      Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppLayout.spacing4),
                    // Last message + unread badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if ((conversation.unreadCount as int) > 0) ...[
                          const SizedBox(width: AppLayout.spacing8),
                          _UnreadBadge(count: conversation.unreadCount as int),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final diff = now.difference(local);

    if (diff.inDays == 0) return DateFormat('HH:mm').format(local);
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return DateFormat('E', 'fr').format(local);
    return DateFormat('dd/MM').format(local);
  }
}

class _ListingImageFallback extends StatelessWidget {
  const _ListingImageFallback({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.imagePlaceholder,
      child: Icon(
        Icons.shopping_bag_outlined,
        color: colors.textTertiary,
        size: 24,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Skeleton tile
// ─────────────────────────────────────────────────────

class _ConversationSkeleton extends StatelessWidget {
  const _ConversationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.screenPadding,
        vertical: AppLayout.spacing12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: 56,
            height: 56,
            borderRadius: AppLayout.borderRadiusMedium,
          ),
          const SizedBox(width: AppLayout.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerBox(width: 130, height: 14),
                    const Spacer(),
                    ShimmerBox(
                      width: 38,
                      height: 11,
                      borderRadius: AppLayout.borderRadiusSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.spacing8),
                ShimmerBox(
                  width: 110,
                  height: 11,
                  borderRadius: AppLayout.borderRadiusSmall,
                ),
                const SizedBox(height: AppLayout.spacing8),
                const ShimmerBox(height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Unread badge
// ─────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final label = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppLayout.radiusFull),
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
