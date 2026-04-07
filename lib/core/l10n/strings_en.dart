const Map<String, String> stringsEn = {
  // App
  'appName': 'Zentrix',
  'premiumStreaming': 'Premium Streaming',

  // Navigation
  'liveTV': 'Live TV',
  'favorites': 'Favorites',
  'guide': 'Guide',
  'settings': 'Settings',

  // Playlist Input
  'addPlaylist': 'Add Playlist',
  'choosePlaylistMethod': 'Choose how to add your IPTV playlist',
  'm3uUrl': 'M3U URL',
  'file': 'File',
  'xtream': 'Xtream',
  'playlistName': 'Playlist Name',
  'playlistNameHint': 'My IPTV',
  'm3uUrlHint': 'http://example.com/playlist.m3u',
  'loadPlaylist': 'Load Playlist',
  'importM3uFile': 'Import M3U File',
  'supportsM3u': 'Supports .m3u and .m3u8 files',
  'chooseFile': 'Choose File',
  'serverUrl': 'Server URL',
  'serverUrlHint': 'http://example.com:8080',
  'username': 'Username',
  'password': 'Password',
  'connect': 'Connect',
  'savedPlaylists': 'Saved Playlists',
  'channels': '{count} channels',
  'enterValidUrl': 'Please enter a valid URL',
  'fillAllFields': 'Please fill in all fields',

  // Home
  'noChannelsLoaded': 'No channels loaded',
  'addPlaylistToStart': 'Add a playlist to get started',
  'allChannels': 'All Channels',

  // Discovery
  'recentlyWatched': 'Recently Watched',
  'continueWatching': 'Continue Watching',
  'trending': 'Trending',
  'popular': 'Popular',
  'seeAll': 'See All',
  'discover': 'Discover',
  'forYou': 'For You',
  'recentlyAdded': 'Recently Added',

  // Search
  'searchChannels': 'Search channels...',
  'searchByNameOrCategory': 'Search by channel name or category',
  'noChannelsFound': 'No channels found',
  'filterByGenre': 'Genre',
  'filterByType': 'Type',
  'allTypes': 'All',
  'sortBy': 'Sort by',
  'sortDefault': 'Default',
  'sortNameAZ': 'Name A-Z',
  'sortNameZA': 'Name Z-A',
  'sortPopular': 'Most Popular',
  'clearFilters': 'Clear Filters',

  // Favorites
  'noFavoritesYet': 'No favorites yet',
  'tapHeartToAdd': 'Tap the heart icon on any channel\nto add it to favorites',

  // EPG
  'tvGuide': 'TV Guide',
  'noEpgData': 'No EPG Data Available',
  'epgAutoLoad': 'EPG data will load automatically\nwhen available from your provider',
  'selectChannelForGuide': 'Select a channel to view guide',
  'now': 'NOW',
  'noProgramData': 'No program data',

  // Player
  'live': 'LIVE',
  'streamUnavailable': 'Stream unavailable',
  'retry': 'Retry',
  'debugLog': 'Debug Log',
  'loadingStream': 'Loading stream...',
  'reconnecting': 'Reconnecting... ({current}/{max})',
  'audioTrack': 'Audio',
  'subtitleTrack': 'Subtitle',
  'aspectRatio': 'Aspect Ratio',
  'playbackSpeed': 'Speed',
  'openExternal': 'Open in External Player',
  'noAudioTracks': 'No audio tracks',
  'noSubtitleTracks': 'No subtitles',
  'off': 'Off',
  'fit': 'Fit',
  'fill': 'Fill',
  'stretch': 'Stretch',
  'speed05': '0.5x',
  'speed075': '0.75x',
  'speed1': '1x',
  'speed125': '1.25x',
  'speed15': '1.5x',
  'speed2': '2x',
  'nextEpisode': 'Next Episode',
  'autoPlayNext': 'Auto-play in {seconds}s',
  'pipMode': 'Picture-in-Picture',

  // Settings
  'appearance': 'Appearance',
  'theme': 'Theme',
  'dark': 'Dark',
  'light': 'Light',
  'system': 'System',
  'playback': 'Playback',
  'bufferDuration': 'Buffer Duration',
  'userAgent': 'User-Agent',
  'customUserAgent': 'Custom User-Agent',
  'enterCustomUserAgent': 'Enter custom User-Agent',
  'playlists': 'Playlists',
  'managePlaylists': 'Manage Playlists',
  'managePlaylistsDesc': 'Add, remove, or update playlists',
  'about': 'About',
  'version': 'Version',
  'aboutDesc': 'Zentrix — A premium IPTV player built with Flutter.\nNo content is included — player only.',
  'language': 'Language',
  'english': 'English',
  'serbian': 'Srpski',
  'save': 'Save',
  'cancel': 'Cancel',

  // Categories
  'categories': 'Categories',

  // Content Types
  'movies': 'Movies',
  'series': 'Series',
  'allMovies': 'All Movies',
  'allSeries': 'All Series',
  'noMoviesLoaded': 'No movies found',
  'noSeriesLoaded': 'No series found',
  'moviesWillAppear': 'Movies from your playlist will appear here',
  'seriesWillAppear': 'Series from your playlist will appear here',
  'episodes': 'Episodes',
  'season': 'Season',
  'episode': 'Episode',

  // Multi-view
  'multiView': 'Multi-View',
  'selectChannels': 'Select channels for multi-view',
  'startMultiView': 'Start Multi-View',
  'selectUpTo4': 'Select 2-4 channels',

  // Channel zapping
  'lastChannel': 'Last Channel',
  'swipeToZap': 'Swipe to change channel',
  'channelUp': 'Channel Up',
  'channelDown': 'Channel Down',

  // Resume
  'resumePlayback': 'Resume',
  'resumeFrom': 'Resume from {position}',
  'startOver': 'Start Over',

  // Parental
  'parentalLock': 'Parental Lock',
  'parentalLockDesc': 'Protect content with a PIN code',
  'setPin': 'Set PIN',
  'enterPin': 'Enter PIN',
  'confirmPin': 'Confirm PIN',
  'pinSet': 'PIN has been set',
  'pinMismatch': 'PINs do not match',
  'wrongPin': 'Wrong PIN',
  'enterCurrentPin': 'Enter current PIN to continue',
  'parentalEnabled': 'Parental lock enabled',
  'parentalDisabled': 'Parental lock disabled',
  'hiddenCategories': 'Hidden Categories',
  'hiddenCategoriesDesc': 'Hide categories behind parental lock',
  'categoryHidden': 'Category hidden',
  'categoryShown': 'Category visible',
  'unlock': 'Unlock',
  'locked': 'Locked',

  // Sorting
  'channelSorting': 'Channel Sorting',
  'sortAZ': 'A-Z',
  'sortZA': 'Z-A',
  'sortCustom': 'Custom',
  'sortRecent': 'Recently Watched',

  // Device
  'deviceInfo': 'Device Info',
  'macAddress': 'MAC Address',
  'copied': 'Copied to clipboard',

  // Misc
  'noResults': 'No results',
  'selectAll': 'Select All',
  'deselectAll': 'Deselect All',
};
