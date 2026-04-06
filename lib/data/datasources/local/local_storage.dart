import 'package:hive_flutter/hive_flutter.dart';
import '../../models/channel_model.dart';
import '../../models/playlist_model.dart';

class LocalStorage {
  Box get _settingsBox => Hive.box('settings');
  Box<String> get _favoritesBox => Hive.box<String>('favorites');
  Box<PlaylistModel> get _playlistsBox => Hive.box<PlaylistModel>('playlists');
  Box<String> get _recentBox => Hive.box<String>('recent_channels');
  Box<ChannelModel> get _channelsBox => Hive.box<ChannelModel>('cached_channels');

  // --- Settings ---

  T getSetting<T>(String key, T defaultValue) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T;
  }

  Future<void> setSetting<T>(String key, T value) {
    return _settingsBox.put(key, value);
  }

  // --- Favorites ---

  Set<String> getFavoriteIds() {
    return _favoritesBox.values.toSet();
  }

  Future<void> addFavorite(String channelId) {
    return _favoritesBox.put(channelId, channelId);
  }

  Future<void> removeFavorite(String channelId) {
    return _favoritesBox.delete(channelId);
  }

  bool isFavorite(String channelId) {
    return _favoritesBox.containsKey(channelId);
  }

  // --- Playlists ---

  List<PlaylistModel> getPlaylists() {
    return _playlistsBox.values.toList();
  }

  Future<void> savePlaylist(PlaylistModel playlist) {
    return _playlistsBox.put(playlist.id, playlist);
  }

  Future<void> deletePlaylist(String id) {
    return _playlistsBox.delete(id);
  }

  // --- Recent Channels ---

  List<String> getRecentChannelIds() {
    return _recentBox.values.toList();
  }

  Future<void> addRecentChannel(String channelId) async {
    final existing = _recentBox.values.toList();
    existing.remove(channelId);
    existing.insert(0, channelId);

    if (existing.length > 50) {
      existing.removeRange(50, existing.length);
    }

    await _recentBox.clear();
    for (var i = 0; i < existing.length; i++) {
      await _recentBox.put('recent_$i', existing[i]);
    }
  }

  String? getLastChannelId() {
    if (_recentBox.isEmpty) return null;
    return _recentBox.getAt(0);
  }

  // --- Cached Channels ---

  Future<void> cacheChannels(List<ChannelModel> channels) async {
    await _channelsBox.clear();
    final map = {for (final ch in channels) ch.id: ch};
    await _channelsBox.putAll(map);
  }

  List<ChannelModel> getCachedChannels() {
    return _channelsBox.values.toList();
  }

  ChannelModel? getChannel(String id) {
    return _channelsBox.get(id);
  }

  Future<void> clearAll() async {
    await _settingsBox.clear();
    await _favoritesBox.clear();
    await _playlistsBox.clear();
    await _recentBox.clear();
    await _channelsBox.clear();
  }
}
