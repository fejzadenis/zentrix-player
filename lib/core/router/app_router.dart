import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/playlist_input/playlist_input_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/player/player_screen.dart';
import '../../presentation/screens/epg/epg_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/favorites/favorites_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/home/shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/playlist-input',
        builder: (context, state) => const PlaylistInputScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FavoritesScreen()),
          ),
          GoRoute(
            path: '/epg',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EpgScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PlayerScreen(
            streamUrl: extra['streamUrl'] as String,
            channelName: extra['channelName'] as String,
            channelId: extra['channelId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
});
