import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';
import 'data/models/channel_model.dart';
import 'data/models/playlist_model.dart';
import 'data/models/epg_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();

  Hive.registerAdapter(ChannelModelAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());
  Hive.registerAdapter(EpgProgramModelAdapter());

  await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox<String>('favorites'),
    Hive.openBox<PlaylistModel>('playlists'),
    Hive.openBox<String>('recent_channels'),
    Hive.openBox<ChannelModel>('cached_channels'),
  ]);

  runApp(const ProviderScope(child: IPTVApp()));
}
