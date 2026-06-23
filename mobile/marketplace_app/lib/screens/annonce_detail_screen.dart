import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../providers/annonces_provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import '../widgets/star_rating.dart';
import '../l10n/app_localizations.dart';
import '../l10n/category_localizations.dart';
import '../providers/reservation_provider.dart';
import 'phone_verification_screen.dart';
import 'seller_showcase_screen.dart';
import '../widgets/user_avatar.dart';

class AnnonceDetailScreen extends StatefulWidget {
  final int annonceId;

  const AnnonceDetailScreen({super.key, required this.annonceId});

  @override
  State<AnnonceDetailScreen> createState() => _AnnonceDetailScreenState();
}

class _AnnonceDetailScreenState extends State<AnnonceDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadAnnonce();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadAnnonce() {
    Provider.of<AnnoncesProvider>(context, listen: false)
        .loadAnnonceDetail(widget.annonceId);
  }

  Future<void> _callSeller(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.cannotOpenPhoneApp)),
        );
      }
    }
  }

  Future<void> _contactSeller(AnnonceDetail annonce) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.mustBeLoggedInToMessage)),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    // Don't allow chatting with yourself
    if (authProvider.user?.id == annonce.seller.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.cannotChatWithSelf)),
      );
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      final conversation = await chatProvider.startConversation(annonce.id);

      if (conversation != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              interlocutorName:
                  conversation.interlocutorName, // This will be seller name
              annonceId: conversation.annonceId,
              annonceTitle: conversation.annonceTitle,
              annonceImage: conversation.annonceImage,
              annoncePrice: conversation.annoncePrice,
              annonceCategoryName: conversation.annonceCategoryName,
              annonceCategoryArName: conversation.annonceCategoryArName,
              annonceStatus: conversation.annonceStatus,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorWithMessage(e.toString())),
          ),
        );
      }
    }
  }

  Future<void> _showRatingDialog(int sellerId, String sellerName) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final colors = Theme.of(context).extension<AppColors>()!;
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.mustBeLoggedInToRate)),
      );
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    int selectedRating = 0;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.rate(sellerName)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: colors.starRating,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() => selectedRating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: AppLayout.spacing16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.commentOptional,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: (isSubmitting || selectedRating == 0)
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          try {
                            await ApiService().submitRating(
                              sellerId: sellerId,
                              rating: selectedRating,
                              comment: commentController.text.trim().isEmpty
                                  ? null
                                  : commentController.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(AppLocalizations.of(context)!
                                        .ratingSentSuccess)),
                              );
                              _loadAnnonce(); // reload to show new rating
                            }
                          } catch (e) {
                            setState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(e
                                        .toString()
                                        .replaceAll('Exception: ', ''))),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.send),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showReservationDialog(AnnonceDetail annonce) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.mustBeLoggedInToMessage)),
      );
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    if (authProvider.user?.phoneVerified != true) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Vérification requise'),
          content: const Text(
              'Veuillez vérifier votre numéro de téléphone avant de réserver.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PhoneVerificationScreen()));
              },
              child: const Text('Vérifier'),
            ),
          ],
        ),
      );
      return;
    }

    bool isSubmitting = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Confirmer votre réservation'),
              content: const Text(
                  'Voulez-vous confirmer votre réservation pour cette annonce ?'),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final reservationProvider =
                              Provider.of<ReservationProvider>(context,
                                  listen: false);
                          final result = await reservationProvider
                              .createReservation(annonce.id);

                          if (ctx.mounted) Navigator.pop(ctx);

                          if (result != null && mounted) {
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (successCtx) => AlertDialog(
                                title:
                                    const Text('Réservation enregistrée'),
                                content: Text(
                                  'Votre réservation a été enregistrée avec succès.\n\nVotre rang est : #${result.rank}',
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(successCtx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } else if (mounted) {
                            final errorMessage =
                                reservationProvider.error ??
                                    'Une erreur est survenue lors de la réservation.\nVeuillez réessayer plus tard.';
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (errorCtx) => AlertDialog(
                                title: const Text('Erreur'),
                                content: Text(errorMessage),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(errorCtx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getStateLabel(String state) {
    switch (state.toLowerCase()) {
      case 'new':
        return AppLocalizations.of(context)!.newCondition;
      case 'used':
        return AppLocalizations.of(context)!.usedCondition;
      default:
        return state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnoncesProvider>(
      builder: (context, provider, child) {
        final annonce = provider.selectedAnnonce;
        final isLoading = provider.isLoading;
        final error = provider.error;

        return Scaffold(
          body: _buildBody(isLoading, error, annonce),
          bottomNavigationBar: _buildBottomBar(context, annonce),
        );
      },
    );
  }

  Widget? _buildBottomBar(BuildContext context, AnnonceDetail? annonce) {
    if (annonce == null) return null;
    final colors = Theme.of(context).extension<AppColors>()!;

    if (annonce.reservationEnabled) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.id == annonce.seller.id) return null;

      return Container(
        padding: const EdgeInsets.all(AppLayout.screenPadding),
        decoration: BoxDecoration(
          color: colors.surfaceElevated1,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReservationDialog(annonce),
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Réserver'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      );
    }

    final hasPhone = annonce.showPhone && annonce.phone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppLayout.screenPadding),
      decoration: BoxDecoration(
        color: colors.surfaceElevated1,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (hasPhone)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callSeller(annonce.phone),
                  icon: const Icon(Icons.phone),
                  label: Text(AppLocalizations.of(context)!.call),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (hasPhone) const SizedBox(width: AppLayout.spacing16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _contactSeller(annonce),
                icon: const Icon(Icons.message),
                label: Text(AppLocalizations.of(context)!.contact),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isLoading, String? error, AnnonceDetail? annonce) {
    final colors = Theme.of(context).extension<AppColors>()!;
    if (isLoading || annonce == null) {
      if (error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.textTertiary),
              const SizedBox(height: AppLayout.spacing16),
              Text(error, style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: AppLayout.spacing16),
              ElevatedButton(
                onPressed: _loadAnnonce,
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return _buildContent(annonce);
  }

  Widget _buildContent(AnnonceDetail annonce) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isGoodDeal = annonce.isGoodDeal;
    final hasSellerRating = annonce.seller.averageRating != null &&
        (annonce.seller.ratingCount ?? 0) > 0;

    return CustomScrollView(
      slivers: [
        // Image Gallery
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(annonce.imageUrls),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price
                Text(
                  annonce.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppLayout.spacing8),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    AppLocalizations.of(context)!
                        .price(annonce.price.toStringAsFixed(0)),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: isGoodDeal ? colors.accent : colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isGoodDeal) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.accentMuted,
                      borderRadius: BorderRadius.circular(AppLayout.radiusFull),
                      border: Border.all(color: colors.accent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 16, color: colors.accent),
                        const SizedBox(width: AppLayout.spacing6),
                        Text(
                          AppLocalizations.of(context)!.goodDeal,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppLayout.spacing16),

                // Tags
                Wrap(
                  spacing: AppLayout.spacing8,
                  runSpacing: AppLayout.spacing8,
                  children: [
                    _buildTag(
                      icon: Icons.category_outlined,
                      label: localizedCategoryText(
                        context,
                        annonce.category,
                        arName: annonce.categoryArName,
                      ),
                    ),
                    _buildTag(
                      icon: Icons.new_releases_outlined,
                      label: _getStateLabel(annonce.state),
                    ),
                    _buildTag(
                      icon: Icons.location_on_outlined,
                      label: '${annonce.wilayaName}, ${annonce.communeName}',
                    ),
                    if (annonce.isExchange)
                      _buildTag(
                        icon: Icons.swap_horiz,
                        label: AppLocalizations.of(context)!.exchangePossible,
                      ),
                  ],
                ),
                const SizedBox(height: AppLayout.spacing24),

                // Description
                Text(
                  AppLocalizations.of(context)!.descriptionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppLayout.spacing8),
                Text(
                  annonce.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppLayout.spacing24),

                // Seller Info
                Container(
                  padding: const EdgeInsets.all(AppLayout.cardPaddingLarge),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppLayout.borderRadiusMedium,
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.seller,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                      ),
                      const SizedBox(height: AppLayout.spacing12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => navigateToSeller(context, annonce.seller.id),
                            child: UserAvatar(
                              avatarUrl: annonce.seller.avatarUrl,
                              name: annonce.seller.name,
                              radius: 24,
                            ),
                          ),
                          const SizedBox(width: AppLayout.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => navigateToSeller(context, annonce.seller.id),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          annonce.seller.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (annonce.seller.isVerifiedSeller) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.verified, size: 16, color: colors.primary),
                                      ],
                                    ],
                                  ),
                                ),
                                if (hasSellerRating) ...[
                                  const SizedBox(height: AppLayout.spacing6),
                                  StarRating(
                                    average: annonce.seller.averageRating!,
                                    count: annonce.seller.ratingCount!,
                                    size: 14,
                                  ),
                                ],
                                const SizedBox(height: AppLayout.spacing4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: colors.textTertiary,
                                    ),
                                    const SizedBox(width: AppLayout.spacing4),
                                    Text(
                                      '${annonce.seller.wilayaName}, ${annonce.seller.communeName}',
                                      style:
                                          TextStyle(color: colors.textTertiary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppLayout.spacing12),
                                OutlinedButton.icon(
                                  onPressed: () => _showRatingDialog(
                                      annonce.seller.id, annonce.seller.name),
                                  icon:
                                      const Icon(Icons.star_outline, size: 18),
                                  label: Text(
                                      AppLocalizations.of(context)!.rateSeller),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12),
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
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(List<ImageUrlDto> imageUrls) {
    final colors = Theme.of(context).extension<AppColors>()!;
    if (imageUrls.isEmpty) {
      return Container(
        color: colors.imagePlaceholder,
        child: Center(
          child: Icon(Icons.image, size: 64, color: colors.textTertiary),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: imageUrls.length,
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
          itemBuilder: (context, index) {
            final imageUrl = imageUrls[index].url;
            return CachedNetworkImage(
              imageUrl: ApiService.getImageUrl(imageUrl) ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: colors.imagePlaceholder,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: colors.imagePlaceholder,
                child: Icon(Icons.error, color: colors.textTertiary),
              ),
            );
          },
        ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageUrls.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? const Color(0xFFFAFAFA)
                        : const Color(0x80FAFAFA),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildTag({required IconData icon, required String label}) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryMuted,
        borderRadius: BorderRadius.circular(AppLayout.radiusXL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: AppLayout.spacing4),
          Text(
            label,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
