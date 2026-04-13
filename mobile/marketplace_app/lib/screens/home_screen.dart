import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/star_rating.dart';
import 'annonce_detail_screen.dart';
import 'category_annonces_screen.dart';
import 'conversation_list_screen.dart';
import 'create_annonce_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

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

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('Marketplace'),
              actions: [
                if (authProvider.isGuest)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Connexion'),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Publier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Text(
            'Decouvrir',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          _buildFeaturedSection(),
          const SizedBox(height: 28),
          _buildSectionHeader(
            title: 'Explorer par categorie',
            subtitle: '',
          ),
          const SizedBox(height: 12),
          _buildCategorySection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    if (_loadingFeatured) {
      return const SizedBox(
        height: 270,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_featuredError != null) {
      return _buildInfoCard(
        icon: Icons.error_outline,
        message: _featuredError!,
        actionLabel: 'Recharger',
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
        message: 'Aucune annonce disponible pour le moment.',
      );
    }

    return SizedBox(
      height: 270,
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
    if (_loadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_categoriesError != null) {
      return _buildInfoCard(
        icon: Icons.category_outlined,
        message: _categoriesError!,
        actionLabel: 'Recharger',
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
        message: 'Aucune categorie disponible.',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _leafCategories.length,
      itemBuilder: (context, index) {
        final category = _leafCategories[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryAnnoncesScreen(
                  categoryId: category.id,
                  categoryName: category.name,
                ),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForCategory(category.name),
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Voir les annonces',
                    style: TextStyle(
                      color: Colors.grey[700],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 12),
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

class _FeaturedAnnonceCard extends StatelessWidget {
  final AnnonceListItem annonce;
  final VoidCallback onTap;

  const _FeaturedAnnonceCard({
    required this.annonce,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSellerRating =
        annonce.sellerRating != null && (annonce.sellerRatingCount ?? 0) > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 215,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: annonce.isGoodDeal
                ? Colors.green.shade300
                : Colors.grey.shade200,
            width: annonce.isGoodDeal ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                      top: Radius.circular(18),
                    ),
                    child: (annonce.mainThumbnailUrl != null || annonce.mainImageUrl != null)
                        ? CachedNetworkImage(
                            imageUrl: ApiService.getImageUrl(
                                annonce.mainThumbnailUrl ?? annonce.mainImageUrl!)!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 42,
                                color: Colors.grey,
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
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Bonne affaire',
                          style: TextStyle(
                            color: Colors.white,
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      annonce.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hasSellerRating) ...[
                      const SizedBox(height: 6),
                      StarRating(
                        average: annonce.sellerRating!,
                        count: annonce.sellerRatingCount!,
                        size: 13,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${annonce.price.toStringAsFixed(0)} DA',
                      style: TextStyle(
                        color: annonce.isGoodDeal
                            ? Colors.green.shade700
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            annonce.wilayaName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
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
