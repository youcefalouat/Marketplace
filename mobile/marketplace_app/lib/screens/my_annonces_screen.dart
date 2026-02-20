import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../providers/annonces_provider.dart';
import '../models/models.dart';
import 'annonce_detail_screen.dart';

class MyAnnoncesScreen extends StatefulWidget {
  const MyAnnoncesScreen({super.key});

  @override
  State<MyAnnoncesScreen> createState() => _MyAnnoncesScreenState();
}

class _MyAnnoncesScreenState extends State<MyAnnoncesScreen> {
  @override
  void initState() {
    super.initState();
    _loadMyAnnonces();
  }

  void _loadMyAnnonces() {
    Provider.of<AnnoncesProvider>(context, listen: false).loadMyAnnonces();
  }

  Future<void> _deleteAnnonce(MyAnnonce annonce) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: Text('Voulez-vous vraiment supprimer "${annonce.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<AnnoncesProvider>(context, listen: false);
      final success = await provider.deleteAnnonce(annonce.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Annonce supprimée' : provider.error ?? 'Erreur'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvée';
      case 'rejected':
        return 'Refusée';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
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
          if (provider.isLoading && provider.myAnnonces.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.myAnnonces.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
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
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Vous n\'avez pas encore d\'annonces',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadMyAnnonces(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myAnnonces.length,
              itemBuilder: (context, index) {
                return _buildAnnonceCard(provider.myAnnonces[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnnonceCard(MyAnnonce annonce) {
    final statusColor = _getStatusColor(annonce.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: annonce.status.toLowerCase() == 'approved'
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnnonceDetailScreen(annonceId: annonce.id),
                  ),
                )
            : null,
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 100,
              height: 100,
              child: annonce.mainImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiService.getImageUrl(annonce.mainImageUrl)!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      annonce.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${annonce.price.toStringAsFixed(0)} €',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(annonce.status),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(annonce.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () => _deleteAnnonce(annonce),
            ),
          ],
        ),
      ),
    );
  }
}
