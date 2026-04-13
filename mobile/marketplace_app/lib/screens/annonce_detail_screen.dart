import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../providers/annonces_provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import '../widgets/star_rating.dart';

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
          const SnackBar(
              content: Text('Impossible d\'ouvrir l\'application téléphone')),
        );
      }
    }
  }

  Future<void> _contactSeller(AnnonceDetail annonce) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous devez être connecté pour envoyer un message')),
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
        const SnackBar(
            content: Text('Vous ne pouvez pas discuter sur votre propre annonce')),
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
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _showRatingDialog(int sellerId, String sellerName) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous devez être connecté pour noter un vendeur')),
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
              title: Text('Noter $sellerName'),
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
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() => selectedRating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
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
                                const SnackBar(
                                    content:
                                        Text('Note envoyée avec succès !')),
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
                      : const Text('Envoyer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'electromenager':
        return 'Électroménager';
      case 'meubles':
        return 'Meubles';
      case 'literie':
        return 'Literie';
      case 'decoration':
        return 'Décoration';
      default:
        return category;
    }
  }

  String _getStateLabel(String state) {
    switch (state.toLowerCase()) {
      case 'new':
        return 'Neuf';
      case 'used':
        return 'Occasion';
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

    final hasPhone = annonce.showPhone && annonce.phone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SafeArea(
        child: Row(
          children: [
            if (hasPhone)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callSeller(annonce.phone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (hasPhone) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _contactSeller(annonce),
                icon: const Icon(Icons.message),
                label: const Text('Contacter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
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
    if (isLoading || annonce == null) {
      if (error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(error),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAnnonce,
                child: const Text('Réessayer'),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price
                Text(
                  annonce.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${annonce.price.toStringAsFixed(0)} DA',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isGoodDeal
                            ? Colors.green.shade700
                            : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isGoodDeal) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green.shade600),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Bonne affaire',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(
                      icon: Icons.category_outlined,
                      label: _getCategoryLabel(annonce.category),
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
                        label: 'Échange possible',
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  annonce.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Seller Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vendeur',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    annonce.seller.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (hasSellerRating) ...[
                                    const SizedBox(height: 6),
                                    StarRating(
                                      average: annonce.seller.averageRating!,
                                      count: annonce.seller.ratingCount!,
                                      size: 14,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${annonce.seller.wilayaName}, ${annonce.seller.communeName}',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _showRatingDialog(
                                        annonce.seller.id, annonce.seller.name),
                                    icon: const Icon(Icons.star_outline,
                                        size: 18),
                                    label: const Text('Noter ce vendeur'),
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
    if (imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, size: 64, color: Colors.grey),
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
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error),
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
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildTag({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
