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

  // --- Discovery ---
  String get recentlyWatched => get('recentlyWatched');
  String get continueWatching => get('continueWatching');
  String get trending => get('trending');
  String get popular => get('popular');
  String get seeAll => get('seeAll');
  String get discover => get('discover');
  String get forYou => get('forYou');
  String get recentlyAdded => get('recentlyAdded');

  // --- Search ---
  String get searchChannels => get('searchChannels');
  String get searchByNameOrCategory => get('searchByNameOrCategory');
  String get noChannelsFound => get('noChannelsFound');
  String get filterByGenre => get('filterByGenre');
  String get filterByType => get('filterByType');
  String get allTypes => get('allTypes');
  String get sortBy => get('sortBy');
  String get sortDefault => get('sortDefault');
  String get sortNameAZ => get('sortNameAZ');
  String get sortNameZA => get('sortNameZA');
  String get sortPopular => get('sortPopular');
  String get clearFilters => get('clearFilters');

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
  String get audioTrack => get('audioTrack');
  String get subtitleTrack => get('subtitleTrack');
  String get aspectRatio => get('aspectRatio');
  String get playbackSpeed => get('playbackSpeed');
  String get openExternal => get('openExternal');
  String get noAudioTracks => get('noAudioTracks');
  String get noSubtitleTracks => get('noSubtitleTracks');
  String get off => get('off');
  String get fit => get('fit');
  String get fill => get('fill');
  String get stretch => get('stretch');
  String get nextEpisode => get('nextEpisode');
  String autoPlayNext(int seconds) =>
      get('autoPlayNext').replaceFirst('{seconds}', '$seconds');
  String get pipMode => get('pipMode');

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

  // --- Multi-view ---
  String get multiView => get('multiView');
  String get selectChannels => get('selectChannels');
  String get startMultiView => get('startMultiView');
  String get selectUpTo4 => get('selectUpTo4');

  // --- Channel zapping ---
  String get lastChannel => get('lastChannel');
  String get swipeToZap => get('swipeToZap');

  // --- Resume ---
  String get resumePlayback => get('resumePlayback');
  String resumeFrom(String position) =>
      get('resumeFrom').replaceFirst('{position}', position);
  String get startOver => get('startOver');

  // --- Parental ---
  String get parentalLock => get('parentalLock');
  String get parentalLockDesc => get('parentalLockDesc');
  String get setPin => get('setPin');
  String get enterPin => get('enterPin');
  String get confirmPin => get('confirmPin');
  String get pinSet => get('pinSet');
  String get pinMismatch => get('pinMismatch');
  String get wrongPin => get('wrongPin');
  String get enterCurrentPin => get('enterCurrentPin');
  String get parentalEnabled => get('parentalEnabled');
  String get parentalDisabled => get('parentalDisabled');
  String get hiddenCategories => get('hiddenCategories');
  String get hiddenCategoriesDesc => get('hiddenCategoriesDesc');
  String get categoryHidden => get('categoryHidden');
  String get categoryShown => get('categoryShown');
  String get unlock => get('unlock');
  String get locked => get('locked');

  // --- Sorting ---
  String get channelSorting => get('channelSorting');
  String get sortAZ => get('sortAZ');
  String get sortZA => get('sortZA');
  String get sortCustom => get('sortCustom');
  String get sortRecent => get('sortRecent');

  // --- License / Paywall ---
  String get paywallTitle => get('paywallTitle');
  String get paywallSubtitle => get('paywallSubtitle');
  String get trialRemainingLabel => get('trialRemainingLabel');
  String get activationCodeHint => get('activationCodeHint');
  String get activate => get('activate');
  String get restoreOrRefresh => get('restoreOrRefresh');
  String get browseLibraryOnly => get('browseLibraryOnly');

  // --- Device ---
  String get deviceInfo => get('deviceInfo');
  String get macAddress => get('macAddress');
  String get copied => get('copied');

  // --- Misc ---
  String get noResults => get('noResults');
  String get selectAll => get('selectAll');
  String get deselectAll => get('deselectAll');
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
