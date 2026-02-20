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
    if (authProvider.user?.id == annonce.seller.name) {
      // Wait, seller.name is not ID. seller info in AnnonceDetail doesn't have ID?
      // AnnonceDetail has `seller` which is `SellerInfo`. SellerInfo has name, phone, locations. No ID?
      // I need to check `AnnonceDetail` model.
    }

    // Check if we have seller ID in AnnonceDetail?
    // The `AnnonceDetail` DTO in backend has `Seller` object.
    // The `SellerInfo` class in mobile has `name`, `phone`, `wilayaName`, `communeName`.
    // It seems I missed `id` in `SellerInfo`?
    // Let's check `backend/MarketplaceApi/DTOs/AnnonceDto.cs` (or Controller map).
    // In `AnnoncesController.cs` MapToDetailDto:
    /*
            Seller = new SellerInfoDto
            {
                Name = annonce.User.Name,
                Phone = annonce.User.Phone,
                WilayaName = annonce.User.Wilaya.Name,
                CommuneName = annonce.User.Commune.Name
            }
    */
    // It does NOT have ID.
    // So I can't check if it's me easily, except maybe comparing names (unreliable).
    // Or I need to add SellerId to AnnonceDetailDto.
    // `Conversation` start endpoint needs `annonceId`.
    // Backend handles "cannot chat with yourself".

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
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
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

  Widget _buildImageGallery(List<String> imageUrls) {
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
            return CachedNetworkImage(
              imageUrl: ApiService.getImageUrl(imageUrls[index])!,
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
