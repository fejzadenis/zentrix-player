import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_app/core/utils/epg_parser.dart';

void main() {
  group('EpgParser', () {
    test('parses valid XMLTV content', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="bbc1.uk">
    <display-name>BBC One</display-name>
  </channel>
  <programme start="20240101120000 +0000" stop="20240101130000 +0000" channel="bbc1.uk">
    <title>News at Noon</title>
    <desc>Latest headlines and breaking news.</desc>
    <category>News</category>
  </programme>
  <programme start="20240101130000 +0000" stop="20240101140000 +0000" channel="bbc1.uk">
    <title>Afternoon Show</title>
    <desc>Entertainment program.</desc>
  </programme>
</tv>''';

      final result = EpgParser.parse(xml);

      expect(result.containsKey('bbc1.uk'), true);
      expect(result['bbc1.uk']!.length, 2);

      final first = result['bbc1.uk']![0];
      expect(first.title, 'News at Noon');
      expect(first.description, 'Latest headlines and breaking news.');
      expect(first.category, 'News');
      expect(first.channelId, 'bbc1.uk');
    });

    test('handles empty XML', () {
      final result = EpgParser.parse('');
      expect(result, isEmpty);
    });

    test('handles malformed XML gracefully', () {
      const xml = '<tv><programme><broken></tv>';
      final result = EpgParser.parse(xml);
      expect(result, isEmpty);
    });

    test('sorts programmes by start time', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240101150000 +0000" stop="20240101160000 +0000" channel="ch1">
    <title>Later Show</title>
  </programme>
  <programme start="20240101120000 +0000" stop="20240101130000 +0000" channel="ch1">
    <title>Earlier Show</title>
  </programme>
</tv>''';

      final result = EpgParser.parse(xml);
      expect(result['ch1']![0].title, 'Earlier Show');
      expect(result['ch1']![1].title, 'Later Show');
    });

    test('parses dates without timezone offset', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240101120000" stop="20240101130000" channel="ch1">
    <title>Test Show</title>
  </programme>
</tv>''';

      final result = EpgParser.parse(xml);
      expect(result.containsKey('ch1'), true);
      expect(result['ch1']!.length, 1);
    });

    test('handles multiple channels', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240101120000 +0000" stop="20240101130000 +0000" channel="ch1">
    <title>Show A</title>
  </programme>
  <programme start="20240101120000 +0000" stop="20240101130000 +0000" channel="ch2">
    <title>Show B</title>
  </programme>
  <programme start="20240101130000 +0000" stop="20240101140000 +0000" channel="ch1">
    <title>Show C</title>
  </programme>
</tv>''';

      final result = EpgParser.parse(xml);
      expect(result.keys.length, 2);
      expect(result['ch1']!.length, 2);
      expect(result['ch2']!.length, 1);
    });
  });
}
