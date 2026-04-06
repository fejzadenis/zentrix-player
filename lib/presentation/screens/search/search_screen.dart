import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/search_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/channel_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

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
    final results = ref.watch(searchResultsProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
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
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: _searchController.text.isEmpty
          ? Center(
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
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : results.isEmpty
              ? Center(
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final channel = results[index];
                    final isFav =
                        ref.watch(favoritesProvider).contains(channel.id);

                    return ChannelTile(
                      channel: channel.copyWith(isFavorite: isFav),
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
                ),
    );
  }
}
