import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/channel_repository_impl.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/channel_repository.dart';
import 'settings_provider.dart';

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  return ChannelRepositoryImpl(ref.watch(localStorageProvider));
});

class ChannelState {
  final List<Channel> channels;
  final List<Channel> filteredChannels;
  final List<Category> categories;
  final String selectedCategory;
  final ContentType selectedContentType;
  final bool isLoading;
  final String? error;

  const ChannelState({
    this.channels = const [],
    this.filteredChannels = const [],
    this.categories = const [],
    this.selectedCategory = 'all',
    this.selectedContentType = ContentType.live,
    this.isLoading = false,
    this.error,
  });

  List<Channel> get liveChannels =>
      channels.where((c) => c.contentType == ContentType.live).toList();

  List<Channel> get movieChannels =>
      channels.where((c) => c.contentType == ContentType.movie).toList();

  List<Channel> get seriesChannels =>
      channels.where((c) => c.contentType == ContentType.series).toList();

  int get liveCount => channels.where((c) => c.contentType == ContentType.live).length;
  int get movieCount => channels.where((c) => c.contentType == ContentType.movie).length;
  int get seriesCount => channels.where((c) => c.contentType == ContentType.series).length;

  ChannelState copyWith({
    List<Channel>? channels,
    List<Channel>? filteredChannels,
    List<Category>? categories,
    String? selectedCategory,
    ContentType? selectedContentType,
    bool? isLoading,
    String? error,
  }) {
    return ChannelState(
      channels: channels ?? this.channels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedContentType: selectedContentType ?? this.selectedContentType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChannelNotifier extends StateNotifier<ChannelState> {
  final ChannelRepository _repository;

  ChannelNotifier(this._repository) : super(const ChannelState());

  Future<void> setChannels(List<Channel> channels) async {
    state = state.copyWith(isLoading: true);

    if (_repository is ChannelRepositoryImpl) {
      (_repository as ChannelRepositoryImpl).setChannels(channels);
    }
    await _repository.cacheChannels(channels);

    _applyContentTypeFilter(channels, ContentType.live);
  }

  Future<void> loadCachedChannels() async {
    state = state.copyWith(isLoading: true);
    try {
      final channels = await _repository.getCachedChannels();
      if (channels.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      if (_repository is ChannelRepositoryImpl) {
        (_repository as ChannelRepositoryImpl).setChannels(channels);
      }

      _applyContentTypeFilter(channels, ContentType.live);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectContentType(ContentType type) {
    _applyContentTypeFilter(state.channels, type);
  }

  void _applyContentTypeFilter(List<Channel> allChannels, ContentType type) {
    final typeChannels = allChannels.where((c) => c.contentType == type).toList();

    final categoryMap = <String, int>{};
    for (final ch in typeChannels) {
      categoryMap[ch.category] = (categoryMap[ch.category] ?? 0) + 1;
    }

    final categories = categoryMap.entries
        .map((e) => Category(id: e.key, name: e.key, channelCount: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final allLabel = type == ContentType.live
        ? 'All Channels'
        : type == ContentType.movie
            ? 'All Movies'
            : 'All Series';

    categories.insert(
      0,
      Category(id: 'all', name: allLabel, channelCount: typeChannels.length),
    );

    state = state.copyWith(
      channels: allChannels,
      filteredChannels: typeChannels,
      categories: categories,
      selectedCategory: 'all',
      selectedContentType: type,
      isLoading: false,
    );
  }

  Future<void> selectCategory(String categoryId) async {
    state = state.copyWith(selectedCategory: categoryId);

    final typeChannels = state.channels
        .where((c) => c.contentType == state.selectedContentType)
        .toList();

    if (categoryId == 'all') {
      state = state.copyWith(filteredChannels: typeChannels);
    } else {
      state = state.copyWith(
        filteredChannels: typeChannels.where((ch) => ch.category == categoryId).toList(),
      );
    }
  }

  void updateChannelFavorite(String channelId, bool isFavorite) {
    final updatedChannels = state.channels.map((ch) {
      if (ch.id == channelId) return ch.copyWith(isFavorite: isFavorite);
      return ch;
    }).toList();

    final updatedFiltered = state.filteredChannels.map((ch) {
      if (ch.id == channelId) return ch.copyWith(isFavorite: isFavorite);
      return ch;
    }).toList();

    state = state.copyWith(
      channels: updatedChannels,
      filteredChannels: updatedFiltered,
    );
  }
}

final channelProvider =
    StateNotifierProvider<ChannelNotifier, ChannelState>((ref) {
  return ChannelNotifier(ref.watch(channelRepositoryProvider));
});
