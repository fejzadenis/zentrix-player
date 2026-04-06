# Zentrix

A premium, production-grade IPTV player built with Flutter. Supports iOS, Android, Windows, macOS, and Linux with a Netflix-level UX.

> **Legal**: This is a player only. No IPTV content is included or distributed.

## Features

- **Multiple playlist sources**: M3U URL, M3U file import, Xtream Codes API
- **Live TV streaming**: HLS support via `video_player`
- **EPG (TV Guide)**: XMLTV parser with timeline UI, current/upcoming programs
- **Channel management**: Grouped by category, logos, lazy loading
- **Favorites**: Add/remove across playlists
- **Search**: Instant search by channel name or category
- **Smart features**: Resume last channel, recently watched, offline metadata caching
- **Video player**: Fullscreen, auto-reconnect on failure, buffering indicator, gesture controls
- **Settings**: Dark/light/system theme, custom User-Agent, buffer duration control
- **Clean architecture**: Presentation / Domain / Data layers with repository pattern

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (latest stable) |
| Language | Dart |
| State Management | Riverpod |
| Video Player | video_player (HLS) |
| Networking | Dio |
| Local Storage | Hive |
| EPG Parsing | xml (XMLTV) |
| Navigation | go_router |
| UI | Material 3, Google Fonts, Shimmer |

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp configuration
├── core/
│   ├── constants/               # App & API constants
│   ├── theme/                   # AppTheme, AppColors
│   ├── router/                  # GoRouter configuration
│   └── utils/                   # M3U parser, EPG parser (with isolates)
├── domain/
│   ├── entities/                # Channel, Category, Playlist, EpgProgram
│   └── repositories/            # Abstract repository contracts
├── data/
│   ├── models/                  # Hive models with TypeAdapters
│   ├── datasources/
│   │   ├── remote/              # M3U datasource, Xtream datasource
│   │   └── local/               # Hive local storage
│   └── repositories/            # Repository implementations
└── presentation/
    ├── providers/               # Riverpod state management
    ├── screens/                 # All app screens
    │   ├── splash/
    │   ├── playlist_input/
    │   ├── home/
    │   ├── player/
    │   ├── epg/
    │   ├── search/
    │   ├── favorites/
    │   └── settings/
    └── widgets/                 # Reusable UI components
```

## Setup

### Prerequisites

- Flutter SDK >= 3.2.0
- Dart >= 3.2.0
- Android Studio / Xcode for platform builds

### Installation

```bash
# Clone or navigate to the project
cd iptv

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### iOS Setup

No additional configuration needed. The `video_player` plugin handles HLS natively on iOS via AVPlayer.

### Android Setup

Add internet permission to `android/app/src/main/AndroidManifest.xml` (usually present by default):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

For HTTP streams (non-HTTPS), add to the `<application>` tag:

```xml
android:usesCleartextTraffic="true"
```

## Usage

### Adding a Playlist

1. **M3U URL**: Paste any M3U/M3U8 playlist URL
2. **File Import**: Pick an `.m3u` or `.m3u8` file from your device
3. **Xtream Codes**: Enter server URL, username, and password

### Sample Test Playlist

You can test with any publicly available M3U playlist. Example format:

```m3u
#EXTM3U
#EXTINF:-1 tvg-id="example" tvg-logo="https://example.com/logo.png" group-title="Test",Test Channel
http://example.com/stream.m3u8
```

## Architecture

The app follows **Clean Architecture** with three layers:

1. **Presentation**: Flutter widgets, Riverpod providers, UI state management
2. **Domain**: Entities (pure Dart classes), repository interfaces
3. **Data**: Models (with Hive adapters), datasources (remote/local), repository implementations

**Key patterns:**
- Repository pattern for data abstraction
- Riverpod for dependency injection and state management
- Isolate-based parsing for large M3U/EPG files (no UI blocking)

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/m3u_parser_test.dart
```

## Performance Optimizations

- **Isolate parsing**: M3U and EPG files are parsed in background isolates
- **Lazy loading**: Channel list uses ListView.builder for virtualized scrolling
- **Hive caching**: Channel data cached locally for instant startup
- **Shimmer loading**: Skeleton screens during data loads
- **Image caching**: Channel logos cached via CachedNetworkImage

## Extending

### Adding PiP Support

Add `flutter_pip` or platform-specific PiP code in `PlayerScreen`.

### Adding Chromecast

Integrate the `cast` package and add a cast button to `PlayerControls`.

### External Player (VLC)

Use `url_launcher` to open stream URLs in VLC:

```dart
launchUrl(Uri.parse('vlc://$streamUrl'));
```

## License

This project is provided as-is for educational purposes. No IPTV content is included.
