import '../entities/channel.dart';
import '../entities/category.dart';

abstract class ChannelRepository {
  Future<List<Channel>> getChannels();
  Future<List<Channel>> getChannelsByCategory(String categoryId);
  Future<List<Category>> getCategories();
  Future<List<Channel>> searchChannels(String query);
  Future<void> cacheChannels(List<Channel> channels);
  Future<List<Channel>> getCachedChannels();
}
