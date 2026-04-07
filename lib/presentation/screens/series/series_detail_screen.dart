import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/channel.dart';
import '../../providers/favorites_provider.dart';

class SeriesGroup {
  final String name;
  final String logoUrl;
  final String category;
  final List<Channel> episodes;
  final Map<int, List<Channel>> seasons;

  SeriesGroup({
    required this.name,
    required this.logoUrl,
    required this.category,
    required this.episodes,
    required this.seasons,
  });
}

final _seasonEpisodeRegex = RegExp(r'[Ss](\d{1,3})\s*[Ee](\d{1,3})');

SeriesGroup buildSeriesGroup(String seriesName, List<Channel> episodes) {
  final seasons = <int, List<Channel>>{};

  for (final ep in episodes) {
    final match = _seasonEpisodeRegex.firstMatch(ep.name);
    final season = match != null ? int.parse(match.group(1)!) : 1;
    seasons.putIfAbsent(season, () => []).add(ep);
  }

  for (final list in seasons.values) {
    list.sort((a, b) {
      final matchA = _seasonEpisodeRegex.firstMatch(a.name);
      final matchB = _seasonEpisodeRegex.firstMatch(b.name);
      final epA = matchA != null ? int.parse(matchA.group(2)!) : 0;
      final epB = matchB != null ? int.parse(matchB.group(2)!) : 0;
      return epA.compareTo(epB);
    });
  }

  final logo = episodes.firstWhere(
    (e) => e.logoUrl.isNotEmpty,
    orElse: () => episodes.first,
  ).logoUrl;

  return SeriesGroup(
    name: seriesName,
    logoUrl: logo,
    category: episodes.first.category,
    episodes: episodes,
    seasons: Map.fromEntries(
      seasons.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
  );
}

String extractSeriesName(String episodeName) {
  final match = _seasonEpisodeRegex.firstMatch(episodeName);
  if (match != null) {
    return episodeName.substring(0, match.start).trim();
  }
  final dashMatch = RegExp(r'\s*[-–]\s*[Ee]p?\s*\d').firstMatch(episodeName);
  if (dashMatch != null) {
    return episodeName.substring(0, dashMatch.start).trim();
  }
  return episodeName;
}

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final String seriesName;
  final List<Channel> episodes;

  const SeriesDetailScreen({
    super.key,
    required this.seriesName,
    required this.episodes,
  });

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen>
    with SingleTickerProviderStateMixin {
  late final SeriesGroup _group;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _group = buildSeriesGroup(widget.seriesName, widget.episodes);
    _tabController = TabController(
      length: _group.seasons.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seasonKeys = _group.seasons.keys.toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_group.logoUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: _group.logoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.darkSurface,
                      ),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? AppColors.darkBg : AppColors.lightBg)
                              .withValues(alpha: 0.8),
                          isDark ? AppColors.darkBg : AppColors.lightBg,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _group.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _group.category,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.tv_rounded,
                                size: 14, color: Colors.white60),
                            const SizedBox(width: 4),
                            Text(
                              '${_group.seasons.length} ${_group.seasons.length == 1 ? "Season" : "Seasons"}',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.play_circle_outline_rounded,
                                size: 14, color: Colors.white60),
                            const SizedBox(width: 4),
                            Text(
                              '${_group.episodes.length} ${l.get('episodes')}',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_group.seasons.length > 1)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SeasonTabBarDelegate(
                tabController: _tabController,
                seasonKeys: seasonKeys,
                isDark: isDark,
              ),
            ),

          SliverFillRemaining(
            child: _group.seasons.length > 1
                ? TabBarView(
                    controller: _tabController,
                    children: seasonKeys.map((season) {
                      return _EpisodeList(
                        episodes: _group.seasons[season]!,
                        seasonNumber: season,
                      );
                    }).toList(),
                  )
                : _EpisodeList(
                    episodes:
                        _group.seasons[seasonKeys.first] ?? _group.episodes,
                    seasonNumber: seasonKeys.first,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SeasonTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<int> seasonKeys;
  final bool isDark;

  _SeasonTabBarDelegate({
    required this.tabController,
    required this.seasonKeys,
    required this.isDark,
  });

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        tabAlignment: TabAlignment.start,
        tabs: seasonKeys
            .map((s) => Tab(text: 'Season $s'))
            .toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SeasonTabBarDelegate oldDelegate) => false;
}

class _EpisodeList extends ConsumerWidget {
  final List<Channel> episodes;
  final int seasonNumber;

  const _EpisodeList({
    required this.episodes,
    required this.seasonNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final ep = episodes[index];
        final match = _seasonEpisodeRegex.firstMatch(ep.name);
        final epNum = match != null ? int.parse(match.group(2)!) : index + 1;
        final isFav = ref.watch(favoritesProvider).contains(ep.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                context.push('/player', extra: {
                  'streamUrl': ep.streamUrl,
                  'channelName': ep.name,
                  'channelId': ep.id,
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: ep.logoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: ep.logoUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Center(
                                  child: Text(
                                    'E$epNum',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                'E$epNum',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Episode $epNum',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ep.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          ref.read(favoritesProvider.notifier).toggle(ep.id),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav
                            ? AppColors.accentAlt
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.play_circle_filled_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
