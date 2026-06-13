import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/seller_models.dart';
import '../providers/seller_provider.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../widgets/marketplace_annonce_preview_card.dart';
import '../widgets/star_rating.dart';
import '../widgets/user_avatar.dart';
import 'annonce_detail_screen.dart';

/// Navigate to SellerShowcaseScreen from anywhere in the app.
void navigateToSeller(BuildContext context, int sellerId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => SellerShowcaseProvider(),
        child: SellerShowcaseScreen(sellerId: sellerId),
      ),
    ),
  );
}

class SellerShowcaseScreen extends StatefulWidget {
  final int sellerId;

  const SellerShowcaseScreen({required this.sellerId, super.key});

  @override
  State<SellerShowcaseScreen> createState() => _SellerShowcaseScreenState();
}

class _SellerShowcaseScreenState extends State<SellerShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final provider = context.read<SellerShowcaseProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadProfile(widget.sellerId);
      provider.loadAnnonces(widget.sellerId);
      provider.loadReviews(widget.sellerId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: Consumer<SellerShowcaseProvider>(
        builder: (context, provider, _) {
          if (provider.loadingProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.profileError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colors.error),
                  const SizedBox(height: 12),
                  Text(provider.profileError!, style: TextStyle(color: colors.textSecondary)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => provider.loadProfile(widget.sellerId),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final profile = provider.profile;
          if (profile == null) return const SizedBox.shrink();

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                forceElevated: innerBoxIsScrolled,
                flexibleSpace: FlexibleSpaceBar(
                  background: _SellerHeader(profile: profile, colors: colors),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.annonces),
                    Tab(text: AppLocalizations.of(context)!.avis),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _AnnoncesTab(sellerId: widget.sellerId),
                _ReviewsTab(sellerId: widget.sellerId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SellerHeader extends StatelessWidget {
  final SellerProfile profile;
  final AppColors colors;

  const _SellerHeader({required this.profile, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 56),
      color: colors.backgroundPrimary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: profile.avatarUrl,
                name: profile.name,
                radius: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.isVerifiedSeller) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified, color: colors.primary, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.communeName}, ${profile.wilayaName}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Membre depuis ${DateFormat('MMMM yyyy', 'fr').format(profile.memberSince.toLocal())}',
                      style: TextStyle(color: colors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profile.averageRating != null) ...[
            StarRating(
              average: profile.averageRating!,
              count: profile.totalReviews,
              size: 16,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              _Stat(label: AppLocalizations.of(context)!.annonces, value: profile.totalAnnonces.toString()),
              const SizedBox(width: 24),
              _Stat(label: AppLocalizations.of(context)!.avis, value: profile.totalReviews.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }
}

class _AnnoncesTab extends StatefulWidget {
  final int sellerId;

  const _AnnoncesTab({required this.sellerId});

  @override
  State<_AnnoncesTab> createState() => _AnnoncesTabState();
}

class _AnnoncesTabState extends State<_AnnoncesTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final provider = context.read<SellerShowcaseProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !provider.loadingMoreAnnonces &&
        provider.hasMoreAnnonces) {
      provider.loadMoreAnnonces(widget.sellerId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).extension<AppColors>()!;

    return Consumer<SellerShowcaseProvider>(
      builder: (context, provider, _) {
        if (provider.loadingAnnonces && provider.annonces.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.annonces.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: colors.textTertiary),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.noAnnoncesYet,
                    style: TextStyle(color: colors.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAnnonces(widget.sellerId, refresh: true),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.annonces.length + (provider.hasMoreAnnonces ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index >= provider.annonces.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final annonce = provider.annonces[index];
              return MarketplaceAnnoncePreviewCard(
                annonceId: annonce.id,
                title: annonce.title,
                imageUrl: annonce.mainThumbnailUrl ?? annonce.mainImageUrl ?? '',
                price: annonce.price,
                categoryName: annonce.category,
                categoryArName: annonce.categoryArName,
                subtitle: '${annonce.communeName}, ${annonce.wilayaName}',
                showActions: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnnonceDetailScreen(annonceId: annonce.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ReviewsTab extends StatefulWidget {
  final int sellerId;

  const _ReviewsTab({required this.sellerId});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final provider = context.read<SellerShowcaseProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !provider.loadingMoreReviews &&
        provider.hasMoreReviews) {
      provider.loadMoreReviews(widget.sellerId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).extension<AppColors>()!;

    return Consumer<SellerShowcaseProvider>(
      builder: (context, provider, _) {
        if (provider.loadingReviews && provider.reviews.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 48, color: colors.textTertiary),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.noReviewsYet,
                    style: TextStyle(color: colors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: provider.reviews.length + (provider.hasMoreReviews ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index >= provider.reviews.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _ReviewTile(review: provider.reviews[index], colors: colors);
          },
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final SellerReview review;
  final AppColors colors;

  const _ReviewTile({required this.review, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            avatarUrl: review.reviewerAvatarUrl,
            name: review.reviewerName,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(review.reviewerName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary)),
                    Text(
                      DateFormat('dd/MM/yyyy').format(review.createdAt.toLocal()),
                      style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      size: 14,
                      color: colors.starRating,
                    ),
                  ),
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(review.comment!,
                      style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
