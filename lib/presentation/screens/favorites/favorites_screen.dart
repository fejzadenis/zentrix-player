import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/channel_tile.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteChannelsProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.favorites),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.noFavoritesYet,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.tapHeartToAdd,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final channel = favorites[index];
                return ChannelTile(
                  channel: channel,
                  onTap: () {
                    context.push('/player', extra: {
                      'streamUrl': channel.streamUrl,
                      'channelName': channel.name,
                      'channelId': channel.id,
                      'channelList': favorites,
                      'currentIndex': index,
                    });
                  },
                  onFavoriteToggle: () {
                    ref.read(favoritesProvider.notifier).toggle(channel.id);
                  },
                );
              },
            ),
    );
  }
}
