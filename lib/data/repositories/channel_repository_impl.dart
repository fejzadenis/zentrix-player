import '../../domain/entities/channel.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/channel_repository.dart';
import '../datasources/local/local_storage.dart';
import '../models/channel_model.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final LocalStorage _localStorage;
  List<Channel> _channels = [];

  ChannelRepositoryImpl(this._localStorage);

  void setChannels(List<Channel> channels) {
    _channels = channels;
  }

  static ContentType _detectTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('/series/')) return ContentType.series;
    if (lower.contains('/movie/') || lower.contains('/movies/')) {
      return ContentType.movie;
    }
    return ContentType.live;
  }

  @override
  Future<List<Channel>> getChannels() async {
    if (_channels.isNotEmpty) return _channels;

    final cached = _localStorage.getCachedChannels();
    final favoriteIds = _localStorage.getFavoriteIds();

    _channels = cached
        .map((m) => m.toEntity(isFavorite: favoriteIds.contains(m.id)))
        .toList();
    return _channels;
  }

  @override
  Future<List<Channel>> getChannelsByCategory(String categoryId) async {
    final all = await getChannels();
    if (categoryId == 'all') return all;
    return all.where((ch) => ch.category == categoryId).toList();
  }

  @override
  Future<List<Category>> getCategories() async {
    final all = await getChannels();
    final categoryMap = <String, int>{};

    for (final channel in all) {
      categoryMap[channel.category] =
          (categoryMap[channel.category] ?? 0) + 1;
    }

    final categories = categoryMap.entries
        .map((e) => Category(id: e.key, name: e.key, channelCount: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    categories.insert(
      0,
      Category(id: 'all', name: 'All', channelCount: all.length),
    );

    return categories;
  }

  @override
  Future<List<Channel>> searchChannels(String query) async {
    final all = await getChannels();
    final lower = query.toLowerCase();
    return all
        .where((ch) =>
            ch.name.toLowerCase().contains(lower) ||
            ch.category.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<void> cacheChannels(List<Channel> channels) async {
    _channels = channels;
    final models = channels.map((ch) => ChannelModel.fromEntity(ch)).toList();
    await _localStorage.cacheChannels(models);
  }

  @override
  Future<List<Channel>> getCachedChannels() async {
    final cached = _localStorage.getCachedChannels();
    final favoriteIds = _localStorage.getFavoriteIds();
    return cached.map((m) {
      final entity = m.toEntity(isFavorite: favoriteIds.contains(m.id));
      final detectedType = _detectTypeFromUrl(entity.streamUrl);
      if (detectedType != entity.contentType) {
        return entity.copyWith(
          contentType: detectedType,
          isLive: detectedType == ContentType.live,
        );
      }
      return entity;
    }).toList();
  }
}
