import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/channel.dart';
import 'channel_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<Channel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final channelState = ref.watch(channelProvider);

  if (query.isEmpty) return [];

  final lower = query.toLowerCase();
  final exact = <Channel>[];
  final fuzzy = <Channel>[];

  for (final ch in channelState.channels) {
    final nameLower = ch.name.toLowerCase();
    final catLower = ch.category.toLowerCase();
    if (nameLower.contains(lower) || catLower.contains(lower)) {
      exact.add(ch);
    } else if (_fuzzyMatch(lower, nameLower)) {
      fuzzy.add(ch);
    }
  }

  return [...exact, ...fuzzy];
});

bool _fuzzyMatch(String pattern, String text) {
  int pi = 0;
  for (int ti = 0; ti < text.length && pi < pattern.length; ti++) {
    if (text[ti] == pattern[pi]) pi++;
  }
  return pi == pattern.length;
}
