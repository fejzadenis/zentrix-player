import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/local_storage.dart';
import '../../domain/entities/channel.dart';
import 'channel_provider.dart';
import 'settings_provider.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final LocalStorage _storage;

  FavoritesNotifier(this._storage) : super({}) {
    state = _storage.getFavoriteIds();
  }

  Future<void> toggle(String channelId) async {
    if (state.contains(channelId)) {
      await _storage.removeFavorite(channelId);
      state = {...state}..remove(channelId);
    } else {
      await _storage.addFavorite(channelId);
      state = {...state, channelId};
    }
  }

  bool isFavorite(String channelId) => state.contains(channelId);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref.watch(localStorageProvider));
});

final favoriteChannelsProvider = Provider<List<Channel>>((ref) {
  final favoriteIds = ref.watch(favoritesProvider);
  final channelState = ref.watch(channelProvider);

  return channelState.channels
      .where((ch) => favoriteIds.contains(ch.id))
      .map((ch) => ch.copyWith(isFavorite: true))
      .toList();
});
