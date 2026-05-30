import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final ApiService _apiService = ApiService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCategoryDialog({CategoryModel? category, int? parentId}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final arNameController =
        TextEditingController(text: category?.arName ?? '');
    final slugController = TextEditingController(text: category?.slug ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                  isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: arNameController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(labelText: 'Nom arabe'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: slugController,
                    decoration: const InputDecoration(labelText: 'Slug'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty ||
                              slugController.text.trim().isEmpty) {
                            return;
                          }

                          setStateDialog(() => isSaving = true);

                          try {
                            if (isEditing) {
                              await _apiService.updateCategory(
                                id: category.id,
                                name: nameController.text.trim(),
                                arName: arNameController.text.trim(),
                                slug: slugController.text.trim(),
                                parentId: category.parentId, // keep same parent
                              );
                            } else {
                              await _apiService.createCategory(
                                name: nameController.text.trim(),
                                arName: arNameController.text.trim(),
                                slug: slugController.text.trim(),
                                parentId:
                                    parentId, // Create under parent if any
                              );
                            }
                            if (mounted) Navigator.pop(context, true);
                          } catch (e) {
                            setStateDialog(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? 'Mettre à jour' : 'Créer'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result == true) {
        _loadCategories();
      }
    });
  }

  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Voulez-vous vraiment supprimer "${category.name}" ?\n\nAttention : Si cette catégorie contient des annonces, elles pourraient être affectées (selon la logique Backend).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              setState(() => _isLoading = true);
              try {
                await _apiService.deleteCategory(category.id);
                _loadCategories();
              } catch (e) {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text('Supprimer',
                style: TextStyle(
                    color: Theme.of(context).extension<AppColors>()!.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNode(CategoryModel category, {int depth = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding:
              EdgeInsets.only(left: 16.0 + (depth * 32.0), right: 16.0),
          title: Text(category.name,
              style: TextStyle(
                  fontWeight:
                      depth == 0 ? FontWeight.bold : FontWeight.normal)),
          subtitle: Text(
            category.arName.isEmpty
                ? 'Slug: ${category.slug}'
                : '${category.arName} • ${category.slug}',
            textDirection:
                category.arName.isEmpty ? TextDirection.ltr : TextDirection.rtl,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (depth == 0)
                IconButton(
                  icon: Icon(Icons.add,
                      color: Theme.of(context).extension<AppColors>()!.accent),
                  tooltip: 'Ajouter une sous-catégorie',
                  onPressed: () => _showCategoryDialog(parentId: category.id),
                ),
              IconButton(
                icon: Icon(Icons.edit,
                    color: Theme.of(context).extension<AppColors>()!.primary),
                tooltip: 'Modifier',
                onPressed: () => _showCategoryDialog(category: category),
              ),
              IconButton(
                icon: Icon(Icons.delete,
                    color: Theme.of(context).extension<AppColors>()!.error),
                tooltip: 'Supprimer',
                onPressed: () => _deleteCategory(category),
              ),
            ],
          ),
        ),
        if (category.subCategories.isNotEmpty)
          ...category.subCategories
              .map((sub) => _buildCategoryNode(sub, depth: depth + 1)),
        if (depth == 0) const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une catégorie principale',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $_error',
                style: TextStyle(
                    color: Theme.of(context).extension<AppColors>()!.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(child: Text('Aucune catégorie trouvée.'));
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryNode(_categories[index]);
      },
    );
  }
}
