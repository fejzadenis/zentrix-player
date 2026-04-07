import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/channel.dart';

class ChannelTile extends StatefulWidget {
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
  State<ChannelTile> createState() => _ChannelTileState();
}

class _ChannelTileState extends State<ChannelTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Material(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) => _pressController.reverse(),
            onTapCancel: () => _pressController.reverse(),
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
                          widget.channel.name,
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
                                widget.channel.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (widget.channel.isLive) ...[
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
                            if (widget.channel.contentType == ContentType.movie) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.movie_rounded, size: 12, color: AppColors.accent),
                            ],
                            if (widget.channel.contentType == ContentType.series) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.tv_rounded, size: 12, color: AppColors.warning),
                            ],
                          ],
                        ),
                        if (widget.currentProgram != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.currentProgram!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
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
                    onTap: widget.onFavoriteToggle,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        widget.channel.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(widget.channel.isFavorite),
                        color: widget.channel.isFavorite
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
      ),
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 50,
        height: 50,
        child: widget.channel.logoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.channel.logoUrl,
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
                    widget.channel.name.isNotEmpty ? widget.channel.name[0].toUpperCase() : '?',
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
