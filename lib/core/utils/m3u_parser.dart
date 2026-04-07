import 'dart:isolate';
import '../../data/models/channel_model.dart';
import '../../domain/entities/channel.dart';

class M3uParser {
  static List<ChannelModel> parse(String content) {
    final channels = <ChannelModel>[];
    final lines = content.split(RegExp(r'\r?\n'));

    String? currentExtInf;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        currentExtInf = line;
      } else if (line.isNotEmpty &&
          !line.startsWith('#') &&
          currentExtInf != null) {
        final channel = _parseChannel(currentExtInf, line, channels.length);
        if (channel != null) {
          channels.add(channel);
        }
        currentExtInf = null;
      }
    }

    return channels;
  }

  static ChannelModel? _parseChannel(String extInf, String url, int index) {
    try {
      final name = _extractName(extInf);
      final tvgId = _extractAttribute(extInf, 'tvg-id');
      final tvgName = _extractAttribute(extInf, 'tvg-name');
      final tvgLogo = _extractAttribute(extInf, 'tvg-logo');
      final groupTitle = _extractAttribute(extInf, 'group-title');

      final type = _detectContentType(
        url,
        groupTitle ?? '',
        tvgName ?? name ?? '',
      );

      return ChannelModel(
        id: tvgId ?? 'ch_$index',
        name: tvgName ?? name ?? 'Unknown Channel',
        logoUrl: tvgLogo ?? '',
        streamUrl: url,
        category: groupTitle ?? 'Uncategorized',
        tvgId: tvgId ?? '',
        isLive: type == ContentType.live,
        contentTypeIndex: type.index,
      );
    } catch (_) {
      return null;
    }
  }

  static ContentType _detectContentType(
      String url, String group, String name) {
    final urlLower = url.toLowerCase();
    if (urlLower.contains('/series/')) return ContentType.series;
    if (urlLower.contains('/movie/') || urlLower.contains('/movies/')) {
      return ContentType.movie;
    }
    return ContentType.live;
  }

  static String? _extractAttribute(String line, String attr) {
    final regex = RegExp('$attr="([^"]*)"', caseSensitive: false);
    final match = regex.firstMatch(line);
    return match?.group(1)?.isEmpty == true ? null : match?.group(1);
  }

  static String? _extractName(String line) {
    final commaIndex = line.lastIndexOf(',');
    if (commaIndex == -1) return null;
    final name = line.substring(commaIndex + 1).trim();
    return name.isEmpty ? null : name;
  }

  static Future<List<ChannelModel>> parseInIsolate(String content) async {
    return Isolate.run(() => parse(content));
  }
}
