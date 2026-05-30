import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/category_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class MarketplaceAnnoncePreviewCard extends StatelessWidget {
  final int annonceId;
  final String title;
  final String imageUrl;
  final double price;
  final String categoryName;
  final String categoryArName;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onMorePressed;
  final bool showActions;

  const MarketplaceAnnoncePreviewCard({
    super.key,
    required this.annonceId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.categoryName,
    required this.categoryArName,
    required this.subtitle,
    required this.onTap,
    this.onMorePressed,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final categoryLabel = localizedCategoryText(
      context,
      categoryName,
      arName: categoryArName,
      fallback: categoryName,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppLayout.borderRadiusLarge,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceElevated1,
            borderRadius: AppLayout.borderRadiusLarge,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewImage(imageUrl: imageUrl),
                    const SizedBox(width: AppLayout.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: colors.primaryMuted,
                                  borderRadius: AppLayout.borderRadiusSmall,
                                ),
                                child: Icon(
                                  Icons.storefront_outlined,
                                  size: 16,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(width: AppLayout.spacing8),
                              Expanded(
                                child: Text(
                                  l10n.marketplaceListing,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppLayout.spacing6),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppLayout.spacing6),
                          Wrap(
                            spacing: AppLayout.spacing8,
                            runSpacing: AppLayout.spacing4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  l10n.price(price.toStringAsFixed(0)),
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (categoryLabel.isNotEmpty)
                                _Badge(
                                  icon: Icons.category_outlined,
                                  label: categoryLabel,
                                ),
                            ],
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: AppLayout.spacing6),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onMorePressed != null)
                      IconButton(
                        tooltip: l10n.moreOptions,
                        icon: const Icon(Icons.more_horiz),
                        color: colors.textSecondary,
                        onPressed: onMorePressed,
                      ),
                  ],
                ),
                if (showActions) ...[
                  const SizedBox(height: AppLayout.spacing12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: onTap,
                          icon: const Icon(Icons.open_in_new, size: 17),
                          label: Text(
                            l10n.viewDetails,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (onMorePressed != null) ...[
                        const SizedBox(width: AppLayout.spacing12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onMorePressed,
                            icon: const Icon(Icons.more_horiz, size: 17),
                            label: Text(
                              l10n.moreOptions,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MarketplaceAnnoncePreviewSkeleton extends StatelessWidget {
  const MarketplaceAnnoncePreviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(AppLayout.cardPadding),
      decoration: BoxDecoration(
        color: colors.surfaceElevated1,
        borderRadius: AppLayout.borderRadiusLarge,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.shimmer,
              borderRadius: AppLayout.borderRadiusMedium,
            ),
          ),
          const SizedBox(width: AppLayout.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(widthFactor: 0.55),
                const SizedBox(height: AppLayout.spacing8),
                _SkeletonLine(widthFactor: 0.9),
                const SizedBox(height: AppLayout.spacing8),
                _SkeletonLine(widthFactor: 0.35),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final String imageUrl;

  const _PreviewImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final resolvedUrl = ApiService.getImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: AppLayout.borderRadiusMedium,
      child: SizedBox(
        width: 68,
        height: 68,
        child: resolvedUrl == null
            ? _ImageFallback(colors: colors)
            : CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.cover,
                httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
                placeholder: (_, __) => Container(
                  color: colors.imagePlaceholder,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _ImageFallback(colors: colors),
              ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final AppColors colors;

  const _ImageFallback({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.imagePlaceholder,
      child: Icon(Icons.image_outlined, color: colors.textTertiary),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.spacing8,
        vertical: AppLayout.spacing4,
      ),
      decoration: BoxDecoration(
        color: colors.primaryMuted,
        borderRadius: BorderRadius.circular(AppLayout.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.primary),
          const SizedBox(width: AppLayout.spacing4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;

  const _SkeletonLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: colors.shimmer,
          borderRadius: BorderRadius.circular(AppLayout.radiusFull),
        ),
      ),
    );
  }
}
