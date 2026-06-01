import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../providers/annonces_provider.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../l10n/category_localizations.dart';
import 'annonce_detail_screen.dart';
import 'moderation_thread_screen.dart';
import 'annonce_conversations_screen.dart';
import 'annonce_reservations_screen.dart';

class MyAnnoncesScreen extends StatefulWidget {
  const MyAnnoncesScreen({super.key});

  @override
  State<MyAnnoncesScreen> createState() => _MyAnnoncesScreenState();
}

class _MyAnnoncesScreenState extends State<MyAnnoncesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMyAnnonces();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMyAnnonces() {
    Provider.of<AnnoncesProvider>(context, listen: false)
        .loadMyAnnonces(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<AnnoncesProvider>(context, listen: false)
          .loadMoreMyAnnonces();
    }
  }

  Future<void> _openAdminChatIfAvailable(MyAnnonce annonce) async {
    final threadId = annonce.moderationThreadId;
    if (threadId == null) return;

    try {
      final thread = await ApiService().getModerationThread(threadId);
      if (!mounted) return;

      if (thread.messages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun message de l\'admin pour le moment.'),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ModerationThreadScreen(threadId: threadId),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun message de l\'admin pour le moment.'),
        ),
      );
    }
  }

  Future<void> _deleteAnnonce(MyAnnonce annonce) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final selectedStatus = await showDialog<AnnonceDeletionStatus>(
      context: context,
      builder: (context) {
        AnnonceDeletionStatus? draftStatus;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Retirer l\'annonce'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pourquoi voulez-vous retirer "${annonce.title}" ?'),
                const SizedBox(height: AppLayout.spacing16),
                RadioGroup<AnnonceDeletionStatus>(
                  groupValue: draftStatus,
                  onChanged: (value) => setState(() => draftStatus = value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final option in AnnonceDeletionStatus.values)
                        RadioListTile<AnnonceDeletionStatus>(
                          value: option,
                          contentPadding: EdgeInsets.zero,
                          title: Text(option.label),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: draftStatus == null
                    ? null
                    : () => Navigator.pop(context, draftStatus),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedStatus != null && mounted) {
      final provider = Provider.of<AnnoncesProvider>(context, listen: false);
      final success = await provider.deleteAnnonce(annonce.id, selectedStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? selectedStatus.successMessage
                : provider.error ?? 'Erreur'),
            backgroundColor: success ? colors.accent : colors.error,
          ),
        );
      }
    }
  }

  void _openConversations(MyAnnonce annonce) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnonceConversationsScreen(
          annonceId: annonce.id,
          annonceTitle: annonce.title,
        ),
      ),
    );
  }

  void _openReservations(MyAnnonce annonce) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnonceReservationsScreen(
          annonceId: annonce.id,
          annonceTitle: annonce.title,
        ),
      ),
    );
  }

  Color _getStatusColor(String status, AppColors colors) {
    switch (status.toLowerCase()) {
      case 'pending':
        return colors.warning;
      case 'underreview':
        return colors.primary;
      case 'approved':
        return colors.accent;
      case 'rejected':
        return colors.error;
      case 'sold':
        return colors.accent;
      case 'archived':
        return colors.textTertiary;
      case 'deleted':
        return colors.textTertiary;
      default:
        return colors.textTertiary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'underreview':
        return 'En révision';
      case 'approved':
        return 'Approuvée';
      case 'rejected':
        return 'Refusée';
      case 'sold':
        return 'Vendue';
      case 'archived':
        return 'Archivee';
      case 'deleted':
        return 'Supprimee';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'underreview':
        return Icons.chat_bubble_outline;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'sold':
        return Icons.sell;
      case 'archived':
        return Icons.archive_outlined;
      case 'deleted':
        return Icons.delete_outline;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes annonces'),
      ),
      body: Consumer<AnnoncesProvider>(
        builder: (context, provider, child) {
          final colors = Theme.of(context).extension<AppColors>()!;

          if (provider.isLoadingMyAnnonces && provider.myAnnonces.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.myAnnonces.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: colors.textTertiary),
                  const SizedBox(height: AppLayout.spacing16),
                  Text(provider.error!,
                      style: TextStyle(color: colors.textSecondary)),
                  const SizedBox(height: AppLayout.spacing16),
                  ElevatedButton(
                    onPressed: _loadMyAnnonces,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.myAnnonces.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt_outlined,
                      size: 64, color: colors.textTertiary),
                  const SizedBox(height: AppLayout.spacing16),
                  Text(
                    'Vous n\'avez pas encore d\'annonces',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final itemCount = provider.myAnnonces.length +
              (provider.hasMoreMyAnnonces ? 1 : 0);

          return RefreshIndicator(
            onRefresh: () async => _loadMyAnnonces(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppLayout.screenPadding),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index >= provider.myAnnonces.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildAnnonceCard(provider.myAnnonces[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnnonceCard(MyAnnonce annonce) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final statusColor = _getStatusColor(annonce.status, colors);
    final isGoodDeal = annonce.isGoodDeal;

    return Card(
      margin: const EdgeInsets.only(bottom: AppLayout.spacing12),
      shape: RoundedRectangleBorder(
        borderRadius: AppLayout.borderRadiusMedium,
        side: isGoodDeal
            ? BorderSide(color: colors.accent, width: 1.2)
            : BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final status = annonce.status.toLowerCase();
          if (status == 'approved') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnnonceDetailScreen(annonceId: annonce.id),
              ),
            );
            return;
          }

          if (status == 'underreview' && annonce.moderationThreadId != null) {
            await _openAdminChatIfAvailable(annonce);
          }
        },
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (annonce.mainThumbnailUrl != null ||
                          annonce.mainImageUrl != null)
                      ? CachedNetworkImage(
                          imageUrl: ApiService.getImageUrl(
                              annonce.mainThumbnailUrl ??
                                  annonce.mainImageUrl!)!,
                          fit: BoxFit.cover,
                          httpHeaders: const {
                            'ngrok-skip-browser-warning': 'true'
                          },
                          placeholder: (context, url) => Container(
                            color: colors.imagePlaceholder,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colors.imagePlaceholder,
                            child: Icon(Icons.image_not_supported,
                                color: colors.textTertiary),
                          ),
                        )
                      : Container(
                          color: colors.imagePlaceholder,
                          child: Icon(Icons.image, color: colors.textTertiary),
                        ),
                  if (isGoodDeal)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius:
                              BorderRadius.circular(AppLayout.radiusFull),
                        ),
                        child: Text(
                          'Bonne affaire',
                          style: TextStyle(
                            color: colors.textOnPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppLayout.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      annonce.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppLayout.spacing4),
                    Text(
                      '${annonce.price.toStringAsFixed(0)} DA',
                      style: TextStyle(
                        color: isGoodDeal ? colors.accent : colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppLayout.spacing4),
                    Text(
                      localizedCategoryText(
                        context,
                        annonce.category,
                        arName: annonce.categoryArName,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppLayout.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: AppLayout.borderRadiusMedium,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(annonce.status),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: AppLayout.spacing4),
                          Flexible(
                            child: Text(
                              _getStatusLabel(annonce.status),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3-dots context menu
            PopupMenuButton<_AnnonceAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                switch (action) {
                  case _AnnonceAction.conversations:
                    _openConversations(annonce);
                    break;
                  case _AnnonceAction.reservations:
                    _openReservations(annonce);
                    break;
                  case _AnnonceAction.delete:
                    _deleteAnnonce(annonce);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _AnnonceAction.conversations,
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 20),
                      SizedBox(width: 12),
                      Text('Conversations'),
                    ],
                  ),
                ),
                if (annonce.reservationEnabled)
                  const PopupMenuItem(
                    value: _AnnonceAction.reservations,
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Réservations'),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _AnnonceAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 20,
                          color: Theme.of(context)
                              .extension<AppColors>()!
                              .error),
                      const SizedBox(width: 12),
                      Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Theme.of(context)
                              .extension<AppColors>()!
                              .error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _AnnonceAction { conversations, reservations, delete }
