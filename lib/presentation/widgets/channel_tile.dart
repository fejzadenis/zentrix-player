import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/channel.dart';

class ChannelTile extends StatelessWidget {
  final Channel channel;
  final String? currentProgram;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ChannelTile({
    super.key,
    required this.channel,
    this.currentProgram,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildLogo(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              channel.category,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (channel.isLive) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.live,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l.live,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.live,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (currentProgram != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentProgram!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      channel.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(channel.isFavorite),
                      color: channel.isFavorite
                          ? AppColors.accentAlt
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 50,
        height: 50,
        child: channel.logoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: channel.logoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.darkCardLight,
                  child: const Icon(Icons.tv, size: 24, color: AppColors.textSecondary),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.darkCardLight,
                  child: const Icon(Icons.tv, size: 24, color: AppColors.textSecondary),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.accent.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    channel.name.isNotEmpty ? channel.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
