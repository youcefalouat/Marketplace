import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/annonces_provider.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import 'annonce_detail_screen.dart';
import '../services/api_service.dart';
import '../widgets/star_rating.dart';
import '../l10n/app_localizations.dart';
import '../widgets/hierarchical_category_selector.dart';

class SearchScreen extends StatefulWidget {
  final String? title;
  final bool lockCategory;
  final bool embedded;

  const SearchScreen({
    super.key,
    this.title,
    this.lockCategory = false,
    this.embedded = false,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
    final l10n = AppLocalizations.of(context)!;
    int? initialCategoryId = provider.categoryIdFilter;
    int? selectedCategoryId = initialCategoryId;

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
                        l10n.filters,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          provider.clearFilters();
                          if (widget.lockCategory &&
                              initialCategoryId != null) {
                            provider.setFilters(categoryId: initialCategoryId);
                          }
                          Navigator.pop(context);
                        },
                        child: Text(l10n.reset),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!widget.lockCategory) ...[
                    // Category filter
                    Text(
                      l10n.category,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _loadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : HierarchicalCategorySelector(
                            categories: _apiCategories,
                            selectedCategoryId: selectedCategoryId,
                            labelText: l10n.category,
                            hintText: l10n.allCategories,
                            allowClear: true,
                            onChanged: (selection) {
                              setModalState(() {
                                selectedCategoryId =
                                    selection?.selectedCategoryId;
                              });
                            },
                          ),
                    const SizedBox(height: 16),
                  ],

                  // Wilaya filter
                  Text(
                    l10n.wilayas,
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
                                    title: Text(l10n.selectWilayas),
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
                              labelText: l10n.allWilayas,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(selectedWilayaIds.isEmpty
                                    ? l10n.allWilayas
                                    : l10n.selectedCount(
                                        selectedWilayaIds.length)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),

                  // Commune filter
                  if (selectedWilayaIds.isNotEmpty) ...[
                    Text(
                      l10n.communes,
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
                                      title: Text(l10n.selectCommunes),
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
                                labelText: l10n.allCommunes,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(selectedCommuneIds.isEmpty
                                      ? l10n.allCommunes
                                      : l10n.selectedCount(
                                          selectedCommuneIds.length)),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                  ],

                  // Price filter
                  Text(
                    l10n.priceDa,
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
                            labelText: l10n.min,
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
                            labelText: l10n.max,
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
                      final finalCategoryId = widget.lockCategory
                          ? initialCategoryId
                          : selectedCategoryId;
                      provider.setFilters(
                        categoryId: finalCategoryId,
                        clearCategory: !widget.lockCategory &&
                            finalCategoryId == null &&
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
                    child: Text(l10n.apply),
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
    if (widget.embedded) {
      return SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSearchHeader(context),
            Expanded(child: _buildBody()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? AppLocalizations.of(context)!.search),
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
            child: _buildSearchField(context),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title ?? AppLocalizations.of(context)!.search,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSearchField(context),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchHint,
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
        final provider = Provider.of<AnnoncesProvider>(context, listen: false);
        provider.setFilters(search: value);
      },
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
                Icon(Icons.error_outline,
                    size: 64,
                    color:
                        Theme.of(context).extension<AppColors>()!.textTertiary),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAnnonces,
                  child: Text(AppLocalizations.of(context)!.retry),
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
                Icon(Icons.inbox_outlined,
                    size: 64,
                    color:
                        Theme.of(context).extension<AppColors>()!.textTertiary),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noAnnoncesFound,
                  style: TextStyle(
                      color: Theme.of(context)
                          .extension<AppColors>()!
                          .textSecondary),
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
              childAspectRatio: 0.68,
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final isGoodDeal = annonce.isGoodDeal;
    final hasSellerRating =
        annonce.sellerRating != null && (annonce.sellerRatingCount ?? 0) > 0;

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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppLayout.borderRadiusMedium,
          side: isGoodDeal
              ? BorderSide(color: colors.accent, width: 1.2)
              : BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
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
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: colors.imagePlaceholder,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colors.imagePlaceholder,
                            child: Icon(Icons.image_not_supported,
                                color: colors.textTertiary),
                          ),
                        )
                      : Container(
                          color: colors.imagePlaceholder,
                          child: Center(
                            child: Icon(Icons.image,
                                size: 48, color: colors.textTertiary),
                          ),
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
                          AppLocalizations.of(context)!.goodDeal,
                          style: TextStyle(
                            color: colors.textOnPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      annonce.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: colors.textPrimary,
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
                      AppLocalizations.of(context)!
                          .price(annonce.price.toStringAsFixed(0)),
                      style: TextStyle(
                        color: isGoodDeal ? colors.accent : colors.primary,
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
                          color: colors.textTertiary,
                        ),
                        const SizedBox(width: 2),
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
