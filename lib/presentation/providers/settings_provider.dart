import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/local_storage.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String userAgent;
  final int bufferDurationMs;
  final String language;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.userAgent = 'Zentrix/1.0',
    this.bufferDurationMs = 30000,
    this.language = 'en',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? userAgent,
    int? bufferDurationMs,
    String? language,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      userAgent: userAgent ?? this.userAgent,
      bufferDurationMs: bufferDurationMs ?? this.bufferDurationMs,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final LocalStorage _storage;

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _load();
  }

  void _load() {
    final themeModeIndex = _storage.getSetting<int>('themeMode', 0);
    final userAgent =
        _storage.getSetting<String>('userAgent', 'Zentrix/1.0');
    final bufferMs = _storage.getSetting<int>('bufferDurationMs', 30000);
    final language = _storage.getSetting<String>('language', 'en');

    state = AppSettings(
      themeMode: ThemeMode.values[themeModeIndex],
      userAgent: userAgent,
      bufferDurationMs: bufferMs,
      language: language,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.setSetting('themeMode', mode.index);
  }

  Future<void> setUserAgent(String agent) async {
    state = state.copyWith(userAgent: agent);
    await _storage.setSetting('userAgent', agent);
  }

  Future<void> setBufferDuration(int ms) async {
    state = state.copyWith(bufferDurationMs: ms);
    await _storage.setSetting('bufferDurationMs', ms);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _storage.setSetting('language', lang);
  }
}

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(localStorageProvider));
});
