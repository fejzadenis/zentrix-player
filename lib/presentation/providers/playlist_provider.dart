import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/remote/m3u_datasource.dart';
import '../../data/datasources/remote/xtream_datasource.dart';
import '../../data/datasources/local/local_storage.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import 'settings_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: AppConstants.connectionTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
  ));
});

final m3uDatasourceProvider = Provider<M3uDatasource>((ref) {
  return M3uDatasource(ref.watch(dioProvider));
});

final xtreamDatasourceProvider = Provider<XtreamDatasource>((ref) {
  return XtreamDatasource(ref.watch(dioProvider));
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl(
    ref.watch(m3uDatasourceProvider),
    ref.watch(xtreamDatasourceProvider),
    ref.watch(localStorageProvider),
  );
});

class PlaylistState {
  final List<Playlist> playlists;
  final Playlist? activePlaylist;
  final bool isLoading;
  final String? error;

  const PlaylistState({
    this.playlists = const [],
    this.activePlaylist,
    this.isLoading = false,
    this.error,
  });

  PlaylistState copyWith({
    List<Playlist>? playlists,
    Playlist? activePlaylist,
    bool? isLoading,
    String? error,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      activePlaylist: activePlaylist ?? this.activePlaylist,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  final PlaylistRepository _repository;

  PlaylistNotifier(this._repository) : super(const PlaylistState()) {
    _loadSavedPlaylists();
  }

  Future<void> _loadSavedPlaylists() async {
    final playlists = await _repository.getSavedPlaylists();
    state = state.copyWith(playlists: playlists);
  }

  Future<List<Channel>> loadM3uUrl(String url, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final channels = await _repository.loadFromM3uUrl(url);

      final playlist = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.isEmpty ? 'M3U Playlist' : name,
        type: PlaylistType.m3uUrl,
        url: url,
        addedAt: DateTime.now(),
        channelCount: channels.length,
      );

      await _repository.savePlaylist(playlist);
      await _loadSavedPlaylists();
      state = state.copyWith(isLoading: false, activePlaylist: playlist);
      return channels;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  Future<List<Channel>> loadM3uFile(String filePath, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final channels = await _repository.loadFromM3uFile(filePath);

      final playlist = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.isEmpty ? 'Imported Playlist' : name,
        type: PlaylistType.m3uFile,
        url: filePath,
        addedAt: DateTime.now(),
        channelCount: channels.length,
      );

      await _repository.savePlaylist(playlist);
      await _loadSavedPlaylists();
      state = state.copyWith(isLoading: false, activePlaylist: playlist);
      return channels;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  Future<List<Channel>> loadXtreamCodes(
    String server,
    String username,
    String password,
    String name,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final channels = await _repository.loadFromXtreamCodes(
        server: server,
        username: username,
        password: password,
      );

      final playlist = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.isEmpty ? 'Xtream Codes' : name,
        type: PlaylistType.xtreamCodes,
        serverUrl: server,
        username: username,
        password: password,
        addedAt: DateTime.now(),
        channelCount: channels.length,
      );

      await _repository.savePlaylist(playlist);
      await _loadSavedPlaylists();
      state = state.copyWith(isLoading: false, activePlaylist: playlist);
      return channels;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  Future<void> deletePlaylist(String id) async {
    await _repository.deletePlaylist(id);
    await _loadSavedPlaylists();
    if (state.activePlaylist?.id == id) {
      state = state.copyWith(
        activePlaylist: state.playlists.isNotEmpty
            ? state.playlists.first
            : null,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, PlaylistState>((ref) {
  return PlaylistNotifier(ref.watch(playlistRepositoryProvider));
});
