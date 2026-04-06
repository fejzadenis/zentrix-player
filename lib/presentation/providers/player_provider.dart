import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/local_storage.dart';
import 'settings_provider.dart';

class PlayerState {
  final String? currentChannelId;
  final String? currentChannelName;
  final String? currentStreamUrl;
  final bool isPlaying;
  final bool isBuffering;
  final bool isFullscreen;
  final Duration position;
  final Duration duration;
  final String? error;
  final int reconnectAttempts;

  const PlayerState({
    this.currentChannelId,
    this.currentChannelName,
    this.currentStreamUrl,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isFullscreen = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
    this.reconnectAttempts = 0,
  });

  PlayerState copyWith({
    String? currentChannelId,
    String? currentChannelName,
    String? currentStreamUrl,
    bool? isPlaying,
    bool? isBuffering,
    bool? isFullscreen,
    Duration? position,
    Duration? duration,
    String? error,
    int? reconnectAttempts,
  }) {
    return PlayerState(
      currentChannelId: currentChannelId ?? this.currentChannelId,
      currentChannelName: currentChannelName ?? this.currentChannelName,
      currentStreamUrl: currentStreamUrl ?? this.currentStreamUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final LocalStorage _storage;

  PlayerNotifier(this._storage) : super(const PlayerState());

  void setChannel(String id, String name, String url) {
    state = state.copyWith(
      currentChannelId: id,
      currentChannelName: name,
      currentStreamUrl: url,
      isPlaying: true,
      isBuffering: true,
      error: null,
      reconnectAttempts: 0,
    );
    _storage.addRecentChannel(id);
  }

  void setPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  void setBuffering(bool buffering) {
    state = state.copyWith(isBuffering: buffering);
  }

  void setFullscreen(bool fullscreen) {
    state = state.copyWith(isFullscreen: fullscreen);
  }

  void setPosition(Duration position) {
    state = state.copyWith(position: position);
  }

  void setDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  void setError(String? error) {
    state = state.copyWith(
      error: error,
      isPlaying: false,
      isBuffering: false,
    );
  }

  void incrementReconnect() {
    state = state.copyWith(
      reconnectAttempts: state.reconnectAttempts + 1,
      isBuffering: true,
      error: null,
    );
  }

  void reset() {
    state = const PlayerState();
  }

  String? get lastChannelId => _storage.getLastChannelId();
  List<String> get recentChannelIds => _storage.getRecentChannelIds();
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.watch(localStorageProvider));
});
