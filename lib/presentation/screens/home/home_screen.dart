import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/channel.dart';
import '../../providers/channel_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/epg_provider.dart';
import '../../providers/watch_history_provider.dart';
import '../../widgets/channel_tile.dart';
import '../../widgets/category_sidebar.dart';
import '../../widgets/shimmer_loading.dart';
import '../series/series_detail_screen.dart';
import '../player/multi_view_screen.dart';

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

  void _openPlayer(Channel channel) {
    final state = ref.read(channelProvider);
    final list = state.filteredChannels;
    final index = list.indexWhere((c) => c.id == channel.id);

    context.push('/player', extra: {
      'streamUrl': channel.streamUrl,
      'channelName': channel.name,
      'channelId': channel.id,
      'channelList': list,
      'currentIndex': index,
    });
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
          if (channelState.liveCount > 1)
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: l.multiView,
              onPressed: () => _showMultiViewPicker(context, ref, channelState, l),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: l.channelSorting,
            onSelected: (value) {
              ref.read(channelProvider.notifier).sortChannels(value);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'az',
                child: _SortMenuItem(icon: Icons.sort_by_alpha_rounded, label: l.sortAZ),
              ),
              PopupMenuItem(
                value: 'za',
                child: _SortMenuItem(icon: Icons.sort_by_alpha_rounded, label: l.sortZA),
              ),
            ],
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

  void _showMultiViewPicker(
    BuildContext context,
    WidgetRef ref,
    ChannelState state,
    AppLocalizations l,
  ) {
    final liveChannels = state.liveChannels;
    final selected = <Channel>{};

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollCtrl) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.multiView, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                l.selectUpTo4,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: selected.length >= 2
                                ? () {
                                    Navigator.pop(ctx);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MultiViewScreen(channels: selected.toList()),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text('${l.startMultiView} (${selected.length})'),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: liveChannels.length,
                        itemBuilder: (_, i) {
                          final ch = liveChannels[i];
                          final isSelected = selected.contains(ch);
                          return ListTile(
                            leading: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                                : const Icon(Icons.radio_button_unchecked, color: Colors.white38),
                            title: Text(ch.name),
                            subtitle: Text(ch.category, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            onTap: () {
                              setSheetState(() {
                                if (isSelected) {
                                  selected.remove(ch);
                                } else if (selected.length < 4) {
                                  selected.add(ch);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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

    final isSeries = state.selectedContentType == ContentType.series;

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
        Expanded(
          child: isSeries
              ? _buildSeriesGrid(context, state.filteredChannels)
              : _buildChannelGrid(context, ref, state),
        ),
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

    final recentlyWatched = ref.watch(recentlyWatchedProvider);
    final continueWatching = ref.watch(continueWatchingProvider);
    final trendingChannels = ref.watch(trendingProvider);
    final favoriteChannels = ref.watch(favoriteChannelsProvider);

    final showDiscovery = state.selectedCategory == 'all';

    return CustomScrollView(
      slivers: [
        if (showDiscovery && favoriteChannels.isNotEmpty)
          SliverToBoxAdapter(
            child: _DiscoverySection(
              title: l.favorites,
              icon: Icons.favorite_rounded,
              iconColor: AppColors.error,
              channels: favoriteChannels,
              onChannelTap: _openPlayer,
            ),
          ),

        if (showDiscovery && continueWatching.isNotEmpty)
          SliverToBoxAdapter(
            child: _DiscoverySection(
              title: l.continueWatching,
              icon: Icons.play_circle_rounded,
              iconColor: AppColors.accent,
              channels: continueWatching,
              onChannelTap: _openPlayer,
            ),
          ),

        if (showDiscovery && recentlyWatched.isNotEmpty)
          SliverToBoxAdapter(
            child: _DiscoverySection(
              title: l.recentlyWatched,
              icon: Icons.history_rounded,
              iconColor: AppColors.primaryLight,
              channels: recentlyWatched,
              onChannelTap: _openPlayer,
            ),
          ),

        if (showDiscovery && trendingChannels.isNotEmpty)
          SliverToBoxAdapter(
            child: _DiscoverySection(
              title: l.trending,
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.warning,
              channels: trendingChannels,
              onChannelTap: _openPlayer,
            ),
          ),

        if (state.categories.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
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
                        ref.read(channelProvider.notifier).selectCategory(cat.id);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        if (state.selectedContentType == ContentType.series)
          SliverToBoxAdapter(
            child: _buildSeriesGrid(context, state.filteredChannels),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final channel = state.filteredChannels[index];
                final epgNotifier = ref.read(epgProvider.notifier);
                final currentProgram = epgNotifier.getCurrentProgram(channel.tvgId);
                final isFav = ref.watch(favoritesProvider).contains(channel.id);

                return RepaintBoundary(
                  child: ChannelTile(
                    channel: channel.copyWith(isFavorite: isFav),
                    currentProgram: currentProgram?.title,
                    onTap: () => _openPlayer(channel),
                    onFavoriteToggle: () {
                      ref.read(favoritesProvider.notifier).toggle(channel.id);
                    },
                  ),
                );
              },
              childCount: state.filteredChannels.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Map<String, List<Channel>> _groupSeries(List<Channel> channels) {
    final groups = <String, List<Channel>>{};
    for (final ch in channels) {
      final name = extractSeriesName(ch.name);
      groups.putIfAbsent(name, () => []).add(ch);
    }
    return Map.fromEntries(
      groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Widget _buildSeriesGrid(BuildContext context, List<Channel> channels) {
    final groups = _groupSeries(channels);
    final entries = groups.entries.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final seriesName = entry.key;
        final episodes = entry.value;
        final logo = episodes.firstWhere(
          (e) => e.logoUrl.isNotEmpty,
          orElse: () => episodes.first,
        ).logoUrl;

        return GestureDetector(
          onTap: () {
            context.push('/series-detail', extra: {
              'seriesName': seriesName,
              'episodes': episodes,
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (logo.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: logo,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              _buildSeriesPlaceholder(seriesName),
                          errorWidget: (_, __, ___) =>
                              _buildSeriesPlaceholder(seriesName),
                        )
                      else
                        _buildSeriesPlaceholder(seriesName),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            '${episodes.length} ep',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  seriesName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeriesPlaceholder(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.accent.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.tv_rounded, size: 40, color: Colors.white38),
      ),
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
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final epgNotifier = ref.read(epgProvider.notifier);
        final currentProgram = epgNotifier.getCurrentProgram(channel.tvgId);
        final isFav = ref.watch(favoritesProvider).contains(channel.id);

        return ChannelTile(
          channel: channel.copyWith(isFavorite: isFav),
          currentProgram: currentProgram?.title,
          onTap: () => _openPlayer(channel),
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

class _DiscoverySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Channel> channels;
  final ValueChanged<Channel> onChannelTap;

  const _DiscoverySection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.channels,
    required this.onChannelTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return GestureDetector(
                onTap: () => onChannelTap(channel),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: channel.logoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: channel.logoUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _buildPlaceholder(channel, isDark),
                                errorWidget: (_, __, ___) =>
                                    _buildPlaceholder(channel, isDark),
                              )
                            : _buildPlaceholder(channel, isDark),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 110,
                        child: Text(
                          channel.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textPrimary : AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Channel channel, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.accent.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: Center(
        child: Text(
          channel.name.isNotEmpty ? channel.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _SortMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SortMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
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
