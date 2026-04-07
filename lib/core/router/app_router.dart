import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/channel.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/playlist_input/playlist_input_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/player/player_screen.dart';
import '../../presentation/screens/epg/epg_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/favorites/favorites_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/home/shell_screen.dart';
import '../../presentation/screens/series/series_detail_screen.dart';
import '../../presentation/screens/paywall/paywall_screen.dart';

CustomTransitionPage<void> _fadeTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideUpTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadeTransition(const SplashScreen(), state),
      ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) => _fadeTransition(const PaywallScreen(), state),
      ),
      GoRoute(
        path: '/playlist-input',
        pageBuilder: (context, state) => _slideUpTransition(const PlaylistInputScreen(), state),
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
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlayerScreen(
              streamUrl: extra['streamUrl'] as String,
              channelName: extra['channelName'] as String,
              channelId: extra['channelId'] as String? ?? '',
              channelList: extra['channelList'] as List<Channel>?,
              currentIndex: extra['currentIndex'] as int? ?? -1,
            ),
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 250),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _slideUpTransition(const SearchScreen(), state),
      ),
      GoRoute(
        path: '/series-detail',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _slideUpTransition(
            SeriesDetailScreen(
              seriesName: extra['seriesName'] as String,
              episodes: extra['episodes'] as List<Channel>,
            ),
            state,
          );
        },
      ),
    ],
  );
});
