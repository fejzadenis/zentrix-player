import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/channel.dart';
import 'channel_provider.dart';
import 'settings_provider.dart';

final recentlyWatchedProvider = Provider<List<Channel>>((ref) {
  final storage = ref.watch(localStorageProvider);
  final channelState = ref.watch(channelProvider);
  final ids = storage.getRecentlyWatchedIds(limit: 20);

  final channelMap = {for (final ch in channelState.channels) ch.id: ch};
  return ids
      .where((id) => channelMap.containsKey(id))
      .map((id) => channelMap[id]!)
      .toList();
});

final continueWatchingProvider = Provider<List<Channel>>((ref) {
  final storage = ref.watch(localStorageProvider);
  final channelState = ref.watch(channelProvider);
  final ids = storage.getContinueWatchingIds(limit: 10);

  final channelMap = {for (final ch in channelState.channels) ch.id: ch};
  return ids
      .where((id) => channelMap.containsKey(id))
      .map((id) => channelMap[id]!)
      .toList();
});

final trendingProvider = Provider<List<Channel>>((ref) {
  final storage = ref.watch(localStorageProvider);
  final channelState = ref.watch(channelProvider);
  final ids = storage.getMostWatchedIds(limit: 20);

  final channelMap = {for (final ch in channelState.channels) ch.id: ch};
  return ids
      .where((id) => channelMap.containsKey(id))
      .map((id) => channelMap[id]!)
      .toList();
});
