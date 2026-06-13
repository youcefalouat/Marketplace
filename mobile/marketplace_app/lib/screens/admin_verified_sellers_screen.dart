import 'package:flutter/material.dart';
import '../models/seller_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import 'seller_showcase_screen.dart';

class AdminVerifiedSellersScreen extends StatefulWidget {
  const AdminVerifiedSellersScreen({super.key});

  @override
  State<AdminVerifiedSellersScreen> createState() =>
      _AdminVerifiedSellersScreenState();
}

class _AdminVerifiedSellersScreenState
    extends State<AdminVerifiedSellersScreen> {
  final _api = ApiService();
  final _scrollController = ScrollController();

  List<AdminUser> _sellers = [];
  bool _loading = false;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;

  String _filter = 'all'; // 'all' | 'true' | 'false'
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _page <= _totalPages) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) { _page = 1; _sellers = []; }
    setState(() => _loading = true);

    try {
      final response = await _api.getAdminSellers(
        verified: _filter,
        search: _search.isEmpty ? null : _search,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _sellers = refresh ? response.items : [..._sellers, ...response.items];
        _totalPages = response.totalPages;
        _page = (refresh ? 1 : _page) + 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page > _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final response = await _api.getAdminSellers(
        verified: _filter,
        search: _search.isEmpty ? null : _search,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _sellers = [..._sellers, ...response.items];
        _totalPages = response.totalPages;
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleVerified(AdminUser seller) async {
    final newValue = !seller.isVerifiedSeller;
    try {
      await _api.setVerifiedSeller(seller.id, isVerified: newValue);
      if (!mounted) return;
      setState(() {
        final idx = _sellers.indexWhere((s) => s.id == seller.id);
        if (idx != -1) {
          _sellers[idx] = AdminUser(
            id: seller.id, name: seller.name, email: seller.email,
            avatarUrl: seller.avatarUrl, communeName: seller.communeName,
            wilayaName: seller.wilayaName, averageRating: seller.averageRating,
            totalAnnonces: seller.totalAnnonces, isVerifiedSeller: newValue,
            createdAt: seller.createdAt,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newValue ? 'Vendeur vérifié' : 'Vérification retirée'),
        backgroundColor: Theme.of(context).extension<AppColors>()!.accent,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).extension<AppColors>()!.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendeurs Vérifiés'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: colors.surfaceElevated1,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    _search = v;
                    _load(refresh: true);
                  },
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    _FilterChip(label: 'Tous', value: 'all', selected: _filter == 'all',
                        onTap: () { _filter = 'all'; _load(refresh: true); }),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Vérifiés', value: 'true', selected: _filter == 'true',
                        onTap: () { _filter = 'true'; _load(refresh: true); }),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Non vérifiés', value: 'false', selected: _filter == 'false',
                        onTap: () { _filter = 'false'; _load(refresh: true); }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading && _sellers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              child: ListView.separated(
                controller: _scrollController,
                itemCount: _sellers.length + (_page <= _totalPages ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= _sellers.length) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator()));
                  }
                  final seller = _sellers[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: GestureDetector(
                      onTap: () => navigateToSeller(context, seller.id),
                      child: UserAvatar(
                          avatarUrl: seller.avatarUrl,
                          name: seller.name,
                          radius: 22),
                    ),
                    title: GestureDetector(
                      onTap: () => navigateToSeller(context, seller.id),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(seller.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (seller.isVerifiedSeller) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified,
                                size: 14, color: colors.primary),
                          ],
                        ],
                      ),
                    ),
                    subtitle: Text(
                      '${seller.communeName}, ${seller.wilayaName} · ${seller.totalAnnonces} annonces',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    ),
                    trailing: Switch(
                      value: seller.isVerifiedSeller,
                      onChanged: (_) => _toggleVerified(seller),
                      activeThumbColor: colors.primary,
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceElevated1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.textOnPrimary : colors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
