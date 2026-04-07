import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/local_storage.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String userAgent;
  final int bufferDurationMs;
  final String language;
  final String parentalPin;
  final bool parentalEnabled;
  final Set<String> hiddenCategories;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.userAgent = 'Zentrix/1.0',
    this.bufferDurationMs = 30000,
    this.language = 'en',
    this.parentalPin = '',
    this.parentalEnabled = false,
    this.hiddenCategories = const {},
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? userAgent,
    int? bufferDurationMs,
    String? language,
    String? parentalPin,
    bool? parentalEnabled,
    Set<String>? hiddenCategories,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      userAgent: userAgent ?? this.userAgent,
      bufferDurationMs: bufferDurationMs ?? this.bufferDurationMs,
      language: language ?? this.language,
      parentalPin: parentalPin ?? this.parentalPin,
      parentalEnabled: parentalEnabled ?? this.parentalEnabled,
      hiddenCategories: hiddenCategories ?? this.hiddenCategories,
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
    final parentalPin = _storage.getSetting<String>('parentalPin', '');
    final parentalEnabled = _storage.getSetting<bool>('parentalEnabled', false);
    final hiddenRaw = _storage.getSetting<String>('hiddenCategories', '');
    final hiddenCategories = hiddenRaw.isEmpty
        ? <String>{}
        : hiddenRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();

    state = AppSettings(
      themeMode: ThemeMode.values[themeModeIndex],
      userAgent: userAgent,
      bufferDurationMs: bufferMs,
      language: language,
      parentalPin: parentalPin,
      parentalEnabled: parentalEnabled,
      hiddenCategories: hiddenCategories,
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

  Future<void> setParentalPin(String pin) async {
    state = state.copyWith(parentalPin: pin);
    await _storage.setSetting('parentalPin', pin);
  }

  Future<void> enableParental(bool enabled) async {
    state = state.copyWith(parentalEnabled: enabled);
    await _storage.setSetting('parentalEnabled', enabled);
  }

  Future<void> toggleCategoryHidden(String category) async {
    final updated = Set<String>.from(state.hiddenCategories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    state = state.copyWith(hiddenCategories: updated);
    await _storage.setSetting('hiddenCategories', updated.join(','));
  }

  bool isCategoryHidden(String category) {
    return state.hiddenCategories.contains(category);
  }

  bool verifyPin(String pin) {
    return state.parentalPin.isNotEmpty && pin == state.parentalPin;
  }
}

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(localStorageProvider));
});

final hiddenCategoriesProvider = Provider<Set<String>>((ref) {
  return ref.watch(settingsProvider).hiddenCategories;
});
