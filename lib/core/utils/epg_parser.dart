import 'dart:isolate';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import '../../data/models/epg_model.dart';

class EpgParser {
  static Map<String, List<EpgProgramModel>> parse(String xmlContent) {
    final result = <String, List<EpgProgramModel>>{};

    try {
      final document = XmlDocument.parse(xmlContent);
      final programmes = document.findAllElements('programme');

      for (final programme in programmes) {
        final channelId = programme.getAttribute('channel') ?? '';
        if (channelId.isEmpty) continue;

        final start = _parseDateTime(programme.getAttribute('start') ?? '');
        final stop = _parseDateTime(programme.getAttribute('stop') ?? '');

        if (start == null || stop == null) continue;

        final titleEl = programme.findElements('title').firstOrNull;
        final descEl = programme.findElements('desc').firstOrNull;
        final categoryEl = programme.findElements('category').firstOrNull;
        final iconEl = programme.findElements('icon').firstOrNull;

        final program = EpgProgramModel(
          channelId: channelId,
          title: titleEl?.innerText ?? 'Unknown',
          description: descEl?.innerText ?? '',
          startTime: start,
          endTime: stop,
          category: categoryEl?.innerText ?? '',
          iconUrl: iconEl?.getAttribute('src') ?? '',
        );

        result.putIfAbsent(channelId, () => []);
        result[channelId]!.add(program);
      }

      for (final programs in result.values) {
        programs.sort((a, b) => a.startTime.compareTo(b.startTime));
      }
    } catch (_) {
      // Return whatever we've parsed so far on malformed XML
    }

    return result;
  }

  static DateTime? _parseDateTime(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final cleaned = dateStr.replaceAll(RegExp(r'\s+'), ' ').trim();
      final format = DateFormat('yyyyMMddHHmmss Z');
      return format.parse(cleaned);
    } catch (_) {
      try {
        final format = DateFormat('yyyyMMddHHmmss');
        return format.parse(dateStr.substring(0, 14));
      } catch (_) {
        return null;
      }
    }
  }

  static Future<Map<String, List<EpgProgramModel>>> parseInIsolate(
    String content,
  ) async {
    return Isolate.run(() => parse(content));
  }
}
