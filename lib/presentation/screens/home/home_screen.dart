import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/channel_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/epg_provider.dart';
import '../../widgets/channel_tile.dart';
import '../../widgets/category_sidebar.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelState = ref.watch(channelProvider);
    final isWide = MediaQuery.of(context).size.width > 600;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            onPressed: () => context.go('/playlist-input'),
          ),
        ],
      ),
      body: channelState.isLoading
          ? const ShimmerChannelList()
          : channelState.channels.isEmpty
              ? _buildEmptyState(context, l)
              : isWide
                  ? _buildWideLayout(context, ref, channelState)
                  : _buildNarrowLayout(context, ref, channelState),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    WidgetRef ref,
    ChannelState state,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: CategorySidebar(
            categories: state.categories,
            selectedCategory: state.selectedCategory,
            onCategorySelected: (id) {
              ref.read(channelProvider.notifier).selectCategory(id);
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildChannelGrid(context, ref, state)),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    WidgetRef ref,
    ChannelState state,
  ) {
    return Column(
      children: [
        if (state.categories.length > 1)
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final cat = state.categories[index];
                final isSelected = cat.id == state.selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text('${cat.name} (${cat.channelCount})'),
                    onSelected: (_) {
                      ref
                          .read(channelProvider.notifier)
                          .selectCategory(cat.id);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        Expanded(child: _buildChannelGrid(context, ref, state)),
      ],
    );
  }

  Widget _buildChannelGrid(
    BuildContext context,
    WidgetRef ref,
    ChannelState state,
  ) {
    final channels = state.filteredChannels;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final epgNotifier = ref.read(epgProvider.notifier);
        final currentProgram = epgNotifier.getCurrentProgram(channel.tvgId);
        final isFav = ref.watch(favoritesProvider).contains(channel.id);

        return ChannelTile(
          channel: channel.copyWith(isFavorite: isFav),
          currentProgram: currentProgram?.title,
          onTap: () {
            context.push('/player', extra: {
              'streamUrl': channel.streamUrl,
              'channelName': channel.name,
              'channelId': channel.id,
            });
          },
          onFavoriteToggle: () {
            ref.read(favoritesProvider.notifier).toggle(channel.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tv_off_rounded,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l.noChannelsLoaded,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l.addPlaylistToStart,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/playlist-input'),
            icon: const Icon(Icons.add),
            label: Text(l.addPlaylist),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
