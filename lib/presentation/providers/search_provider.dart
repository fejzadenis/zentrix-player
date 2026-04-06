import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/channel.dart';
import 'channel_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<Channel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final channelState = ref.watch(channelProvider);

  if (query.isEmpty) return [];

  final lower = query.toLowerCase();
  return channelState.channels
      .where((ch) =>
          ch.name.toLowerCase().contains(lower) ||
          ch.category.toLowerCase().contains(lower))
      .toList();
});
