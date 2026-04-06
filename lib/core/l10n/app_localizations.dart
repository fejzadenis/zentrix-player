import 'package:flutter/material.dart';
import 'strings_en.dart';
import 'strings_sr.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('sr'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': stringsEn,
    'sr': stringsSr,
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // --- App ---
  String get appName => get('appName');
  String get premiumStreaming => get('premiumStreaming');

  // --- Navigation ---
  String get liveTV => get('liveTV');
  String get favorites => get('favorites');
  String get guide => get('guide');
  String get settings => get('settings');

  // --- Playlist Input ---
  String get addPlaylist => get('addPlaylist');
  String get choosePlaylistMethod => get('choosePlaylistMethod');
  String get m3uUrl => get('m3uUrl');
  String get file => get('file');
  String get xtream => get('xtream');
  String get playlistName => get('playlistName');
  String get playlistNameHint => get('playlistNameHint');
  String get m3uUrlHint => get('m3uUrlHint');
  String get loadPlaylist => get('loadPlaylist');
  String get importM3uFile => get('importM3uFile');
  String get supportsM3u => get('supportsM3u');
  String get chooseFile => get('chooseFile');
  String get serverUrl => get('serverUrl');
  String get serverUrlHint => get('serverUrlHint');
  String get username => get('username');
  String get password => get('password');
  String get connect => get('connect');
  String get savedPlaylists => get('savedPlaylists');
  String channelCount(int count) => get('channels').replaceFirst('{count}', '$count');
  String get enterValidUrl => get('enterValidUrl');
  String get fillAllFields => get('fillAllFields');

  // --- Home ---
  String get noChannelsLoaded => get('noChannelsLoaded');
  String get addPlaylistToStart => get('addPlaylistToStart');
  String get allChannels => get('allChannels');

  // --- Search ---
  String get searchChannels => get('searchChannels');
  String get searchByNameOrCategory => get('searchByNameOrCategory');
  String get noChannelsFound => get('noChannelsFound');

  // --- Favorites ---
  String get noFavoritesYet => get('noFavoritesYet');
  String get tapHeartToAdd => get('tapHeartToAdd');

  // --- EPG ---
  String get tvGuide => get('tvGuide');
  String get noEpgData => get('noEpgData');
  String get epgAutoLoad => get('epgAutoLoad');
  String get selectChannelForGuide => get('selectChannelForGuide');
  String get now => get('now');
  String get noProgramData => get('noProgramData');

  // --- Player ---
  String get live => get('live');
  String get streamUnavailable => get('streamUnavailable');
  String get retry => get('retry');
  String get debugLog => get('debugLog');
  String get loadingStream => get('loadingStream');
  String reconnecting(int current, int max) =>
      get('reconnecting').replaceFirst('{current}', '$current').replaceFirst('{max}', '$max');

  // --- Settings ---
  String get appearance => get('appearance');
  String get theme => get('theme');
  String get dark => get('dark');
  String get light => get('light');
  String get system => get('system');
  String get playback => get('playback');
  String get bufferDuration => get('bufferDuration');
  String get userAgent => get('userAgent');
  String get customUserAgent => get('customUserAgent');
  String get enterCustomUserAgent => get('enterCustomUserAgent');
  String get playlists => get('playlists');
  String get managePlaylists => get('managePlaylists');
  String get managePlaylistsDesc => get('managePlaylistsDesc');
  String get about => get('about');
  String get version => get('version');
  String get aboutDesc => get('aboutDesc');
  String get language => get('language');
  String get english => get('english');
  String get serbian => get('serbian');
  String get save => get('save');
  String get cancel => get('cancel');

  // --- Categories ---
  String get categories => get('categories');

  // --- Content Types ---
  String get movies => get('movies');
  String get series => get('series');
  String get allMovies => get('allMovies');
  String get allSeries => get('allSeries');
  String get noMoviesLoaded => get('noMoviesLoaded');
  String get noSeriesLoaded => get('noSeriesLoaded');
  String get moviesWillAppear => get('moviesWillAppear');
  String get seriesWillAppear => get('seriesWillAppear');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'sr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
