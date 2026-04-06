import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/channel.dart';
import '../../providers/channel_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/epg_provider.dart';
import '../../widgets/channel_tile.dart';
import '../../widgets/category_sidebar.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final type = ContentType.values[_tabController.index];
    ref.read(channelProvider.notifier).selectContentType(type);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: channelState.channels.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(46),
                child: _buildContentTypeTabs(channelState, l),
              ),
      ),
      body: channelState.isLoading
          ? const ShimmerChannelList()
          : channelState.channels.isEmpty
              ? _buildEmptyState(context, l)
              : isWide
                  ? _buildWideLayout(context, ref, channelState)
                  : _buildNarrowLayout(context, ref, channelState, l),
    );
  }

  Widget _buildContentTypeTabs(ChannelState state, AppLocalizations l) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: AppColors.primaryGradient,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.live_tv_rounded, size: 16),
                const SizedBox(width: 6),
                Text(l.liveTV),
                if (state.liveCount > 0) ...[
                  const SizedBox(width: 4),
                  _CountBadge(count: state.liveCount),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.movie_rounded, size: 16),
                const SizedBox(width: 6),
                Text(l.movies),
                if (state.movieCount > 0) ...[
                  const SizedBox(width: 4),
                  _CountBadge(count: state.movieCount),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tv_rounded, size: 16),
                const SizedBox(width: 6),
                Text(l.series),
                if (state.seriesCount > 0) ...[
                  const SizedBox(width: 4),
                  _CountBadge(count: state.seriesCount),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    WidgetRef ref,
    ChannelState state,
  ) {
    if (state.filteredChannels.isEmpty) {
      return _buildContentEmptyState(context, state.selectedContentType);
    }

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
    AppLocalizations l,
  ) {
    if (state.filteredChannels.isEmpty) {
      return _buildContentEmptyState(context, state.selectedContentType);
    }

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

  Widget _buildContentEmptyState(BuildContext context, ContentType type) {
    final l = AppLocalizations.of(context);

    final IconData icon;
    final String title;
    final String subtitle;

    switch (type) {
      case ContentType.live:
        icon = Icons.live_tv_rounded;
        title = l.noChannelsLoaded;
        subtitle = l.addPlaylistToStart;
      case ContentType.movie:
        icon = Icons.movie_rounded;
        title = l.noMoviesLoaded;
        subtitle = l.moviesWillAppear;
      case ContentType.series:
        icon = Icons.tv_rounded;
        title = l.noSeriesLoaded;
        subtitle = l.seriesWillAppear;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
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

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  String get _label {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
