import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/channel.dart';
import '../../providers/search_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/channel_tile.dart';

enum SearchSortMode { none, nameAZ, nameZA, popular }

final _searchSortProvider = StateProvider<SearchSortMode>((ref) => SearchSortMode.none);
final _searchTypeFilterProvider = StateProvider<ContentType?>((ref) => null);
final _searchCategoryFilterProvider = StateProvider<String?>((ref) => null);

final _filteredSearchResultsProvider = Provider<List<Channel>>((ref) {
  var results = ref.watch(searchResultsProvider);
  final typeFilter = ref.watch(_searchTypeFilterProvider);
  final catFilter = ref.watch(_searchCategoryFilterProvider);
  final sort = ref.watch(_searchSortProvider);

  if (typeFilter != null) {
    results = results.where((ch) => ch.contentType == typeFilter).toList();
  }
  if (catFilter != null && catFilter.isNotEmpty) {
    results = results.where((ch) => ch.category == catFilter).toList();
  }

  switch (sort) {
    case SearchSortMode.nameAZ:
      results = List.of(results)..sort((a, b) => a.name.compareTo(b.name));
    case SearchSortMode.nameZA:
      results = List.of(results)..sort((a, b) => b.name.compareTo(a.name));
    case SearchSortMode.popular:
      final favs = ref.watch(favoritesProvider);
      results = List.of(results)
        ..sort((a, b) {
          final aFav = favs.contains(a.id) ? 1 : 0;
          final bFav = favs.contains(b.id) ? 1 : 0;
          return bFav.compareTo(aFav);
        });
    case SearchSortMode.none:
      break;
  }

  return results;
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(_filteredSearchResultsProvider);
    final rawResults = ref.watch(searchResultsProvider);
    final l = AppLocalizations.of(context);
    final activeTypeFilter = ref.watch(_searchTypeFilterProvider);
    final activeCatFilter = ref.watch(_searchCategoryFilterProvider);
    final activeSort = ref.watch(_searchSortProvider);
    final hasActiveFilters = activeTypeFilter != null ||
        activeCatFilter != null ||
        activeSort != SearchSortMode.none;

    final allCategories = _extractCategories(rawResults);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: l.searchChannels,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: hasActiveFilters ? AppColors.primary : null,
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
                setState(() {});
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters && _searchController.text.isNotEmpty)
            _buildFilterBar(context, l, allCategories, activeTypeFilter,
                activeCatFilter, activeSort, hasActiveFilters),

          Expanded(
            child: _searchController.text.isEmpty
                ? _buildIdleState(context, l)
                : results.isEmpty
                    ? _buildEmptyState(context, l)
                    : _buildResultsList(results),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    AppLocalizations l,
    List<String> categories,
    ContentType? activeType,
    String? activeCat,
    SearchSortMode activeSort,
    bool hasActive,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkCardLight : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: l.allTypes,
                  isSelected: activeType == null,
                  onTap: () =>
                      ref.read(_searchTypeFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 6),
                _FilterChipButton(
                  label: l.liveTV,
                  icon: Icons.live_tv_rounded,
                  isSelected: activeType == ContentType.live,
                  onTap: () => ref.read(_searchTypeFilterProvider.notifier).state =
                      ContentType.live,
                ),
                const SizedBox(width: 6),
                _FilterChipButton(
                  label: l.movies,
                  icon: Icons.movie_rounded,
                  isSelected: activeType == ContentType.movie,
                  onTap: () => ref.read(_searchTypeFilterProvider.notifier).state =
                      ContentType.movie,
                ),
                const SizedBox(width: 6),
                _FilterChipButton(
                  label: l.series,
                  icon: Icons.tv_rounded,
                  isSelected: activeType == ContentType.series,
                  onTap: () => ref.read(_searchTypeFilterProvider.notifier).state =
                      ContentType.series,
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 24, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(width: 12),
                _SortButton(
                  label: l.sortDefault,
                  isSelected: activeSort == SearchSortMode.none,
                  onTap: () =>
                      ref.read(_searchSortProvider.notifier).state = SearchSortMode.none,
                ),
                const SizedBox(width: 6),
                _SortButton(
                  label: l.sortNameAZ,
                  isSelected: activeSort == SearchSortMode.nameAZ,
                  onTap: () =>
                      ref.read(_searchSortProvider.notifier).state = SearchSortMode.nameAZ,
                ),
                const SizedBox(width: 6),
                _SortButton(
                  label: l.sortNameZA,
                  isSelected: activeSort == SearchSortMode.nameZA,
                  onTap: () =>
                      ref.read(_searchSortProvider.notifier).state = SearchSortMode.nameZA,
                ),
                const SizedBox(width: 6),
                _SortButton(
                  label: l.sortPopular,
                  icon: Icons.trending_up,
                  isSelected: activeSort == SearchSortMode.popular,
                  onTap: () =>
                      ref.read(_searchSortProvider.notifier).state = SearchSortMode.popular,
                ),
              ],
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipButton(
                    label: l.filterByGenre,
                    icon: Icons.label_outline_rounded,
                    isSelected: activeCat == null,
                    onTap: () =>
                        ref.read(_searchCategoryFilterProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 6),
                  ...categories.take(15).map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _FilterChipButton(
                            label: cat,
                            isSelected: activeCat == cat,
                            onTap: () => ref
                                .read(_searchCategoryFilterProvider.notifier)
                                .state = cat,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
          if (hasActive)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(_searchTypeFilterProvider.notifier).state = null;
                  ref.read(_searchCategoryFilterProvider.notifier).state = null;
                  ref.read(_searchSortProvider.notifier).state = SearchSortMode.none;
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: Text(l.clearFilters, style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentAlt,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _extractCategories(List<Channel> channels) {
    final cats = <String>{};
    for (final ch in channels) {
      if (ch.category.isNotEmpty && ch.category != 'Uncategorized') {
        cats.add(ch.category);
      }
    }
    final list = cats.toList()..sort();
    return list;
  }

  Widget _buildIdleState(BuildContext context, AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l.searchByNameOrCategory,
            style: const TextStyle(color: AppColors.textSecondary),
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
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l.noChannelsFound,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<Channel> results) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final channel = results[index];
        final isFav = ref.watch(favoritesProvider).contains(channel.id);

        return ChannelTile(
          channel: channel.copyWith(isFavorite: isFav),
          onTap: () {
            context.push('/player', extra: {
              'streamUrl': channel.streamUrl,
              'channelName': channel.name,
              'channelId': channel.id,
              'channelList': results,
              'currentIndex': index,
            });
          },
          onFavoriteToggle: () {
            ref.read(favoritesProvider.notifier).toggle(channel.id);
          },
        );
      },
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
