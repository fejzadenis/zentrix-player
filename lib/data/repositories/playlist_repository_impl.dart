import 'dart:io';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/channel.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../datasources/remote/m3u_datasource.dart';
import '../datasources/remote/xtream_datasource.dart';
import '../datasources/local/local_storage.dart';
import '../models/playlist_model.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final M3uDatasource _m3uDatasource;
  final XtreamDatasource _xtreamDatasource;
  final LocalStorage _localStorage;

  PlaylistRepositoryImpl(
    this._m3uDatasource,
    this._xtreamDatasource,
    this._localStorage,
  );

  @override
  Future<List<Channel>> loadFromM3uUrl(String url) async {
    final models = await _m3uDatasource.fetchFromUrl(url);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Channel>> loadFromM3uFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }
    final content = await file.readAsString();
    final models = await _m3uDatasource.parseFromContent(content);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Channel>> loadFromXtreamCodes({
    required String server,
    required String username,
    required String password,
  }) async {
    await _xtreamDatasource.authenticate(
      server: server,
      username: username,
      password: password,
    );

    final models = await _xtreamDatasource.getLiveStreams(
      server: server,
      username: username,
      password: password,
    );

    final categoriesModels = await _xtreamDatasource.getLiveCategories(
      server: server,
      username: username,
      password: password,
    );

    final categoryMap = {
      for (final cat in categoriesModels) cat.id: cat.name,
    };

    for (final model in models) {
      model.category = categoryMap[model.category] ?? model.category;
    }

    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    final model = PlaylistModel.fromEntity(playlist);
    await _localStorage.savePlaylist(model);
  }

  @override
  Future<List<Playlist>> getSavedPlaylists() async {
    final models = _localStorage.getPlaylists();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await _localStorage.deletePlaylist(id);
  }

  @override
  Future<void> updatePlaylist(Playlist playlist) async {
    final model = PlaylistModel.fromEntity(playlist);
    await _localStorage.savePlaylist(model);
  }
}
