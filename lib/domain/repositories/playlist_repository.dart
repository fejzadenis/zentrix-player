import '../entities/playlist.dart';
import '../entities/channel.dart';

abstract class PlaylistRepository {
  Future<List<Channel>> loadFromM3uUrl(String url);
  Future<List<Channel>> loadFromM3uFile(String filePath);
  Future<List<Channel>> loadFromXtreamCodes({
    required String server,
    required String username,
    required String password,
  });
  Future<void> savePlaylist(Playlist playlist);
  Future<List<Playlist>> getSavedPlaylists();
  Future<void> deletePlaylist(String id);
  Future<void> updatePlaylist(Playlist playlist);
}
