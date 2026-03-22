import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/annonces_provider.dart';
import '../models/models.dart';
import 'annonce_detail_screen.dart';
import 'create_annonce_screen.dart';
import 'my_annonces_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'conversation_list_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  List<CategoryModel> _apiCategories = [];
  bool _loadingCategories = true;

  List<Wilaya> _wilayas = [];
  bool _loadingWilayas = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadWilayas();
    _loadAnnonces();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService().getCategories();
      if (!mounted) return;
      setState(() {
        _apiCategories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadWilayas() async {
    try {
      final wilayas = await ApiService().getWilayas();
      if (!mounted) return;
      setState(() {
        _wilayas = wilayas;
        _loadingWilayas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingWilayas = false);
    }
  }

  Future<List<Commune>> _loadCommunesForFilter(int wilayaId) async {
    try {
      return await ApiService().getCommunes(wilayaId);
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadAnnonces() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AnnoncesProvider>(context, listen: false);
      provider.loadAnnonces(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<AnnoncesProvider>(context, listen: false).loadMore();
    }
  }

  void _showFilterDialog() {
    final provider = Provider.of<AnnoncesProvider>(context, listen: false);
    int? initialCategoryId = provider.categoryIdFilter;
    CategoryModel? selectedParentCategory;
    CategoryModel? selectedSubCategory;

    if (initialCategoryId != null) {
      for (var parent in _apiCategories) {
        if (parent.id == initialCategoryId) {
          selectedParentCategory = parent;
          break;
        }
        for (var sub in parent.subCategories) {
          if (sub.id == initialCategoryId) {
            selectedParentCategory = parent;
            selectedSubCategory = sub;
            break;
          }
        }
        if (selectedParentCategory != null) break;
      }
    }

    List<int> selectedWilayaIds = provider.wilayaFilters?.toList() ?? [];
    List<int> selectedCommuneIds = provider.communeFilters?.toList() ?? [];
    List<Commune> filterCommunes = [];
    bool loadingFilterCommunes = false;

    final minPriceController = TextEditingController(
      text: provider.minPrice?.toString() ?? '',
    );
    final maxPriceController = TextEditingController(
      text: provider.maxPrice?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> loadRelevantCommunes() async {
              if (selectedWilayaIds.isEmpty) {
                setModalState(() {
                  filterCommunes = [];
                  selectedCommuneIds = [];
                });
                return;
              }
              setModalState(() {
                loadingFilterCommunes = true;
              });
              List<Commune> allRelevant = [];
              for (int wId in selectedWilayaIds) {
                try {
                  final res = await _loadCommunesForFilter(wId);
                  allRelevant.addAll(res);
                } catch (_) {}
              }
              setModalState(() {
                filterCommunes = allRelevant;
                // Verify selected communes are still in the relevant list
                selectedCommuneIds
                    .removeWhere((id) => !allRelevant.any((c) => c.id == id));
                loadingFilterCommunes = false;
              });
            }

            // Initial load if wilayas are pre-selected
            if (selectedWilayaIds.isNotEmpty &&
                filterCommunes.isEmpty &&
                !loadingFilterCommunes) {
              loadRelevantCommunes();
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtres',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category filter
                  Text(
                    'Catégorie',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _loadingCategories
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<CategoryModel>(
                          initialValue: selectedParentCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Toutes les catégories',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<CategoryModel>(
                              value: null,
                              child: Text('Toutes'),
                            ),
                            ..._apiCategories.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                )),
                          ],
                          onChanged: (category) {
                            setModalState(() {
                              selectedParentCategory = category;
                              selectedSubCategory = null;
                            });
                          },
                        ),
                  const SizedBox(height: 16),

                  if (selectedParentCategory != null &&
                      selectedParentCategory!.subCategories.isNotEmpty) ...[
                    DropdownButtonFormField<CategoryModel>(
                      initialValue: selectedSubCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Sous-catégorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<CategoryModel>(
                          value: null,
                          child: Text('Toutes'),
                        ),
                        ...selectedParentCategory!.subCategories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                )),
                      ],
                      onChanged: (category) {
                        setModalState(() => selectedSubCategory = category);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Wilaya filter
                  Text(
                    'Wilayas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _loadingWilayas
                      ? const Center(child: CircularProgressIndicator())
                      : InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                return StatefulBuilder(
                                    builder: (ctx, setDialogState) {
                                  return AlertDialog(
                                    title: const Text('Sélectionner Wilayas'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _wilayas.length,
                                        itemBuilder: (ctx, index) {
                                          final w = _wilayas[index];
                                          final isSelected =
                                              selectedWilayaIds.contains(w.id);
                                          return CheckboxListTile(
                                            title:
                                                Text('${w.code} - ${w.name}'),
                                            value: isSelected,
                                            onChanged: (val) {
                                              setDialogState(() {
                                                if (val == true) {
                                                  selectedWilayaIds.add(w.id);
                                                } else {
                                                  selectedWilayaIds
                                                      .remove(w.id);
                                                }
                                              });
                                              setModalState(() {});
                                              loadRelevantCommunes();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                });
                              },
                            );
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Toutes les wilayas',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(selectedWilayaIds.isEmpty
                                    ? 'Toutes les wilayas'
                                    : '${selectedWilayaIds.length} sélectionnée(s)'),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),

                  // Commune filter
                  if (selectedWilayaIds.isNotEmpty) ...[
                    Text(
                      'Communes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    loadingFilterCommunes
                        ? const Center(child: CircularProgressIndicator())
                        : InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  return StatefulBuilder(
                                      builder: (ctx, setDialogState) {
                                    return AlertDialog(
                                      title:
                                          const Text('Sélectionner Communes'),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: filterCommunes.length,
                                          itemBuilder: (ctx, index) {
                                            final c = filterCommunes[index];
                                            final isSelected =
                                                selectedCommuneIds
                                                    .contains(c.id);
                                            return CheckboxListTile(
                                              title: Text(c.name),
                                              value: isSelected,
                                              onChanged: (val) {
                                                setDialogState(() {
                                                  if (val == true) {
                                                    selectedCommuneIds
                                                        .add(c.id);
                                                  } else {
                                                    selectedCommuneIds
                                                        .remove(c.id);
                                                  }
                                                });
                                                setModalState(() {});
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    );
                                  });
                                },
                              );
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Toutes les communes',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(selectedCommuneIds.isEmpty
                                      ? 'Toutes les communes'
                                      : '${selectedCommuneIds.length} sélectionnée(s)'),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                  ],

                  // Price filter
                  Text(
                    'Prix',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Min',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Max',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Apply button
                  ElevatedButton(
                    onPressed: () {
                      final finalCategoryId =
                          selectedSubCategory?.id ?? selectedParentCategory?.id;
                      provider.setFilters(
                        categoryId: finalCategoryId,
                        clearCategory: finalCategoryId == null &&
                            initialCategoryId != null,
                        minPrice: double.tryParse(minPriceController.text),
                        maxPrice: double.tryParse(maxPriceController.text),
                        wilayaIds: selectedWilayaIds,
                        communeIds: selectedCommuneIds,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                final provider =
                    Provider.of<AnnoncesProvider>(context, listen: false);
                provider.setFilters(search: value);
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

          if (index > 0 && !authProvider.isAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
            return;
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateAnnonceScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConversationListScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyAnnoncesScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
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
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Mes annonces',
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

  Widget _buildBody() {
    return Consumer<AnnoncesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.annonces.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null && provider.annonces.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAnnonces,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (provider.annonces.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune annonce trouvée',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.loadAnnonces(refresh: true);
          },
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: provider.annonces.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.annonces.length) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return _buildAnnonceCard(provider.annonces[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnnonceCard(AnnonceListItem annonce) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnonceDetailScreen(annonceId: annonce.id),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: annonce.mainImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiService.getImageUrl(annonce.mainImageUrl)!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
                    ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      annonce.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${annonce.price.toStringAsFixed(0)} DA',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
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
