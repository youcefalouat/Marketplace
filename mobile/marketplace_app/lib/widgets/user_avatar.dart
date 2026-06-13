import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const UserAvatar({
    required this.avatarUrl,
    required this.name,
    this.radius = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = ApiService.getImageUrl(avatarUrl);

    if (fullUrl != null) {
      return CachedNetworkImage(
        imageUrl: fullUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (_, __) => _initials(context),
        errorWidget: (_, __, ___) => _initials(context),
        memCacheWidth: (radius * 2 * 3).toInt(),
        memCacheHeight: (radius * 2 * 3).toInt(),
      );
    }

    return _initials(context);
  }

  Widget _initials(BuildContext context) {
    final initials = _getInitials(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
