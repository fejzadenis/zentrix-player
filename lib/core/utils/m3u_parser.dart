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

      final type = _detectContentType(url, groupTitle ?? '', tvgName ?? name ?? '');

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

  /// Detection priority:
  /// 1. Group-title keywords (most reliable for multi-type M3U playlists)
  /// 2. URL path for /movie/ and /series/ (but NOT /live/ — many providers
  ///    route everything through /live/)
  /// 3. File extension (.mp4, .mkv → movie)
  /// 4. Season/episode pattern in name → series
  /// 5. Default → live
  static ContentType _detectContentType(String url, String group, String name) {
    final groupLower = group.toLowerCase().trim();

    // 1) Group-title keywords first — they're set by the provider and most reliable
    if (_seriesGroupWords.hasMatch(groupLower)) return ContentType.series;
    if (_movieGroupWords.hasMatch(groupLower)) return ContentType.movie;

    // 2) URL path (only /movie/ and /series/ — not /live/ since providers
    //    often serve everything under /live/)
    final urlLower = url.toLowerCase();
    if (urlLower.contains('/series/')) return ContentType.series;
    if (urlLower.contains('/movie/') || urlLower.contains('/movies/')) {
      return ContentType.movie;
    }

    // 3) File extension → movie/VOD
    if (_vodExtension.hasMatch(urlLower)) return ContentType.movie;

    // 4) Season/episode pattern in channel name → series
    if (_seasonEpisodePattern.hasMatch(name)) return ContentType.series;

    // 5) Default → live
    return ContentType.live;
  }

  static final _vodExtension = RegExp(
    r'\.(mp4|mkv|avi|mov|flv|wmv|webm|m4v|mpg|mpeg)(\?|$)',
  );

  /// Matches series-related group titles in multiple languages
  static final _seriesGroupWords = RegExp(
    // English
    r'\bseries\b|\bseasons?\b|\bepisodes?\b|\btv.?shows?\b'
    // Serbian / Balkan
    r'|\bserij[ae]\b|\bserije\b|\bsezon[ae]?\b|\bepizod[ae]?\b'
    r'|\bcrtane\s*serije\b|\banimirane\s*serije\b|\bturske\s*serije\b'
    r'|\bkorejske\s*serije\b|\bdomace\s*serije\b|\bstrane\s*serije\b'
    r'|\bex.?yu\s*serije\b|\bnove\s*serije\b|\bserije\s*\d{4}\b'
    // Generic patterns
    r'|\btelenovela\b|\bsoap\b|\bminiseries\b',
    caseSensitive: false,
  );

  /// Matches movie/VOD-related group titles in multiple languages
  static final _movieGroupWords = RegExp(
    // Explicit VOD/Movie/Film keywords
    r'\bvod\b|\bmovies?\b|\bfilms?\b|\bfilmov[ie]\b|\bcinema\b|\bkino\b'
    // Serbian genre names (these categories are almost always movies)
    r'|\bakcija\b|\bavantura\b|\bkomedija\b|\bkomedije\b'
    r'|\bhoror\b|\bhorror\b|\btriler\b|\bthriller\b'
    r'|\bdrama\b|\bdrame\b|\bdramas?\b'
    r'|\bsci.?fi\b|\bfantasy\b|\bfantastika\b'
    r'|\bromantic\b|\bromantics?\b|\bromantika\b|\bromantični\b'
    r'|\bwestern\b|\bwesterns?\b'
    r'|\bmystery\b|\bmisterija\b|\bmisterije\b'
    r'|\bcrime\b|\bkrimi\b|\bkriminal\b'
    r'|\bbiograf\w*\b|\bbiography\b'
    r'|\bratni\b|\bwar\b'
    r'|\bhistori\w*\b|\bistorijsk\w*\b'
    r'|\bmusical\b|\bmjuzikl\b'
    r'|\bfamily\b|\bporodic\w*\b'
    r'|\bdocumentar\w*\b|\bdokumentar\w*\b'
    r'|\banimation\b|\banimirani?\b|\bcrtani\b|\bcrtaći\b'
    r'|\bbollywood\b|\bindian\b|\bindijsk\w*\b'
    r'|\bturski\b|\bturkish\b'
    r'|\b4k\b|\buhd\b'
    // Serbian compound movie categories
    r'|\bdomaci\s*film\b|\bstrani\s*film\b|\bcrtani\s*film\b'
    r'|\bnovi\s*film\b|\bex.?yu\s*film\b'
    r'|\bbozicn\w*\b|\bchristmas\b'
    r'|\bkids\b|\bdjecj\w*\b|\bdecij\w*\b|\bdečij\w*\b'
    // Actor name patterns (FIRST LAST format, all caps = movie category)
    r'|\b[A-Z]{2,}\s+[A-Z]{2,}\b',
    caseSensitive: false,
  );

  static final _seasonEpisodePattern = RegExp(
    r'[Ss]\d{1,2}\s*[Ee]\d{1,2}',
  );

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
