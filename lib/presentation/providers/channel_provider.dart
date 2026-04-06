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
  final bool isLoading;
  final String? error;

  const ChannelState({
    this.channels = const [],
    this.filteredChannels = const [],
    this.categories = const [],
    this.selectedCategory = 'all',
    this.isLoading = false,
    this.error,
  });

  ChannelState copyWith({
    List<Channel>? channels,
    List<Channel>? filteredChannels,
    List<Category>? categories,
    String? selectedCategory,
    bool? isLoading,
    String? error,
  }) {
    return ChannelState(
      channels: channels ?? this.channels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
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

    final categories = await _repository.getCategories();

    state = state.copyWith(
      channels: channels,
      filteredChannels: channels,
      categories: categories,
      selectedCategory: 'all',
      isLoading: false,
    );
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
      final categories = await _repository.getCategories();

      state = state.copyWith(
        channels: channels,
        filteredChannels: channels,
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectCategory(String categoryId) async {
    state = state.copyWith(isLoading: true, selectedCategory: categoryId);
    final filtered = await _repository.getChannelsByCategory(categoryId);
    state = state.copyWith(filteredChannels: filtered, isLoading: false);
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
