import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/star_rating.dart';
import 'annonce_detail_screen.dart';
import 'category_annonces_screen.dart';
import 'conversation_list_screen.dart';
import 'create_annonce_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../l10n/app_localizations.dart';
import '../l10n/category_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  int _currentIndex = 0;
  bool _loadingFeatured = true;
  bool _loadingCategories = true;
  String? _featuredError;
  String? _categoriesError;
  List<AnnonceListItem> _featuredAnnonces = [];
  List<CategoryModel> _leafCategories = [];

  @override
  void initState() {
    super.initState();
    _loadAccueilData();
  }

  Future<void> _loadAccueilData() async {
    await Future.wait([
      _loadFeaturedAnnonces(),
      _loadLeafCategories(),
    ]);
  }

  Future<void> _loadFeaturedAnnonces() async {
    try {
      final featured = await _apiService.getFeaturedAnnonces(count: 20);
      if (!mounted) return;
      setState(() {
        _featuredAnnonces = featured;
        _loadingFeatured = false;
        _featuredError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingFeatured = false;
        _featuredError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadLeafCategories() async {
    try {
      final categories = await _apiService.getCategories();
      if (!mounted) return;
      setState(() {
        _leafCategories = _extractLeafCategories(categories);
        _loadingCategories = false;
        _categoriesError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoriesError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<CategoryModel> _extractLeafCategories(List<CategoryModel> categories) {
    final leaves = <CategoryModel>[];

    void collect(CategoryModel category) {
      if (category.subCategories.isEmpty) {
        leaves.add(category);
        return;
      }

      for (final subCategory in category.subCategories) {
        collect(subCategory);
      }
    }

    for (final category in categories) {
      collect(category);
    }

    return leaves;
  }

  Future<void> _openProtectedScreen(Widget screen) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _onTapBottomNav(int index) {
    switch (index) {
      case 0:
      case 1:
        setState(() => _currentIndex = index);
        break;
      case 2:
        _openProtectedScreen(const CreateAnnonceScreen());
        break;
      case 3:
      case 4:
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!authProvider.isAuthenticated) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        }
        setState(() => _currentIndex = index);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final unreadMessageCount = context.watch<ChatProvider>().totalUnreadCount;

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const AppLogo(
                size: 42,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              actions: [
                if (authProvider.isGuest)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.login),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => setState(() => _currentIndex = 4),
                  ),
              ],
            )
          : null,
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTapBottomNav,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: AppLocalizations.of(context)!.search,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: AppLocalizations.of(context)!.publish,
          ),
          BottomNavigationBarItem(
            icon: _BottomNavBadge(
              icon: Icons.message_outlined,
              count: unreadMessageCount,
            ),
            activeIcon: _BottomNavBadge(
              icon: Icons.message,
              count: unreadMessageCount,
            ),
            label: AppLocalizations.of(context)!.messages,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 1:
        return const SearchScreen(embedded: true);
      case 3:
        return const ConversationListScreen();
      case 4:
        return const ProfileScreen();
      case 0:
      default:
        return _buildAccueilBody();
    }
  }

  Widget _buildAccueilBody() {
    return RefreshIndicator(
      onRefresh: _loadAccueilData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppLayout.screenPadding,
          AppLayout.spacing20,
          AppLayout.screenPadding,
          28,
        ),
        children: [
          Text(
            AppLocalizations.of(context)!.discover,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppLayout.spacing16),
          _buildFeaturedSection(),
          const SizedBox(height: 28),
          _buildSectionHeader(
            title: AppLocalizations.of(context)!.exploreByCategory,
            subtitle: '',
          ),
          const SizedBox(height: AppLayout.spacing12),
          _buildCategorySection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppLayout.spacing4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    const featuredCarouselHeight = 292.0;

    if (_loadingFeatured) {
      return const SizedBox(
        height: featuredCarouselHeight,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_featuredError != null) {
      return _buildInfoCard(
        icon: Icons.error_outline,
        message: _featuredError!,
        actionLabel: AppLocalizations.of(context)!.reload,
        onPressed: () {
          setState(() {
            _loadingFeatured = true;
            _featuredError = null;
          });
          _loadFeaturedAnnonces();
        },
      );
    }

    if (_featuredAnnonces.isEmpty) {
      return _buildInfoCard(
        icon: Icons.inbox_outlined,
        message: AppLocalizations.of(context)!.noAnnoncesAvailable,
      );
    }

    return SizedBox(
      height: featuredCarouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredAnnonces.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final annonce = _featuredAnnonces[index];
          return _FeaturedAnnonceCard(
            annonce: annonce,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnnonceDetailScreen(annonceId: annonce.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategorySection() {
    final colors = Theme.of(context).extension<AppColors>()!;

    if (_loadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppLayout.spacing24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_categoriesError != null) {
      return _buildInfoCard(
        icon: Icons.category_outlined,
        message: _categoriesError!,
        actionLabel: AppLocalizations.of(context)!.reload,
        onPressed: () {
          setState(() {
            _loadingCategories = true;
            _categoriesError = null;
          });
          _loadLeafCategories();
        },
      );
    }

    if (_leafCategories.isEmpty) {
      return _buildInfoCard(
        icon: Icons.category_outlined,
        message: AppLocalizations.of(context)!.noCategoriesAvailable,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppLayout.spacing12,
        mainAxisSpacing: AppLayout.spacing12,
        childAspectRatio: 1.2,
      ),
      itemCount: _leafCategories.length,
      itemBuilder: (context, index) {
        final category = _leafCategories[index];
        final categoryName = localizedCategoryName(context, category);
        return InkWell(
          borderRadius: BorderRadius.circular(AppLayout.radiusLarge),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryAnnoncesScreen(
                  categoryId: category.id,
                  categoryName: categoryName,
                ),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppLayout.radiusLarge),
              color: colors.surfaceElevated1,
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppLayout.cardPaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryMuted,
                      borderRadius: AppLayout.borderRadiusMedium,
                    ),
                    child: Icon(
                      _iconForCategory(category.name),
                      color: colors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    categoryName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppLayout.spacing6),
                  Text(
                    AppLocalizations.of(context)!.viewAnnonces,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppLayout.spacing20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppLayout.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: colors.textTertiary),
          const SizedBox(height: AppLayout.spacing12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: AppLayout.spacing12),
            OutlinedButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForCategory(String categoryName) {
    final normalized = categoryName.toLowerCase();
    if (normalized.contains('electro')) return Icons.kitchen_outlined;
    if (normalized.contains('meuble')) return Icons.chair_outlined;
    if (normalized.contains('literie')) return Icons.bed_outlined;
    if (normalized.contains('decor')) return Icons.weekend_outlined;
    if (normalized.contains('telephone')) return Icons.smartphone_outlined;
    if (normalized.contains('auto')) return Icons.directions_car_outlined;
    return Icons.grid_view_rounded;
  }
}

class _BottomNavBadge extends StatelessWidget {
  final IconData icon;
  final int count;

  const _BottomNavBadge({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final label = count > 99 ? '99+' : count.toString();

    return SizedBox(
      width: 30,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Icon(icon),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colors.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colors.navBarBackground,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textOnPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedAnnonceCard extends StatelessWidget {
  final AnnonceListItem annonce;
  final VoidCallback onTap;

  const _FeaturedAnnonceCard({
    required this.annonce,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final hasSellerRating =
        annonce.sellerRating != null && (annonce.sellerRatingCount ?? 0) > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 215,
        decoration: BoxDecoration(
          color: colors.surfaceElevated1,
          borderRadius: BorderRadius.circular(AppLayout.radiusLarge),
          border: Border.all(
            color: annonce.isGoodDeal ? colors.accent : colors.border,
            width: annonce.isGoodDeal ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppLayout.radiusLarge),
                    ),
                    child: (annonce.mainThumbnailUrl != null ||
                            annonce.mainImageUrl != null)
                        ? CachedNetworkImage(
                            imageUrl: ApiService.getImageUrl(
                                annonce.mainThumbnailUrl ??
                                    annonce.mainImageUrl!)!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: colors.imagePlaceholder,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: colors.imagePlaceholder,
                              child: Icon(Icons.image_not_supported,
                                  color: colors.textTertiary),
                            ),
                          )
                        : Container(
                            color: colors.imagePlaceholder,
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 42,
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                  ),
                  if (annonce.isGoodDeal)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius:
                              BorderRadius.circular(AppLayout.radiusFull),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.goodDeal,
                          style: TextStyle(
                            color: colors.textOnPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
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
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (hasSellerRating) ...[
                      const SizedBox(height: AppLayout.spacing6),
                      StarRating(
                        average: annonce.sellerRating!,
                        count: annonce.sellerRatingCount!,
                        size: 13,
                      ),
                    ],
                    const Spacer(),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        AppLocalizations.of(context)!
                            .price(annonce.price.toStringAsFixed(0)),
                        style: TextStyle(
                          color: annonce.isGoodDeal
                              ? colors.accent
                              : colors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppLayout.spacing6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(width: AppLayout.spacing4),
                        Expanded(
                          child: Text(
                            annonce.wilayaName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
