import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AnnonceReservationsScreen extends StatefulWidget {
  final int annonceId;
  final String annonceTitle;

  const AnnonceReservationsScreen({
    super.key,
    required this.annonceId,
    required this.annonceTitle,
  });

  @override
  State<AnnonceReservationsScreen> createState() =>
      _AnnonceReservationsScreenState();
}

class _AnnonceReservationsScreenState
    extends State<AnnonceReservationsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Reservation> _reservations = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

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
        !_isLoadingMore &&
        _page < _totalPages) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 1;
      _reservations = [];
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAnnonceReservations(
        widget.annonceId,
        page: _page,
      );
      setState(() {
        _reservations = response.items;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _page >= _totalPages) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await _apiService.getAnnonceReservations(
        widget.annonceId,
        page: _page + 1,
      );
      setState(() {
        _page++;
        _reservations.addAll(response.items);
        _totalPages = response.totalPages;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _callBuyer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir l\'application téléphone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Réservations'),
            Text(
              widget.annonceTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColors colors) {
    if (_isLoading && _reservations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.textTertiary),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _load(refresh: true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: colors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Aucune réservation pour cette annonce',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    final itemCount =
        _reservations.length + (_page < _totalPages ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= _reservations.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildReservationTile(_reservations[index], colors);
        },
      ),
    );
  }

  Widget _buildReservationTile(Reservation reservation, AppColors colors) {
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm')
        .format(reservation.reservationDateTime.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: AppLayout.borderRadiusMedium,
        side: BorderSide(color: colors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.cardPadding),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryMuted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '#${reservation.rank}',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Buyer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: colors.textTertiary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (reservation.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 13, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          reservation.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Call button
            if (reservation.phone.isNotEmpty)
              IconButton(
                icon: Icon(Icons.call, color: colors.accent),
                tooltip: 'Appeler',
                onPressed: () => _callBuyer(reservation.phone),
              ),
          ],
        ),
      ),
    );
  }
}
