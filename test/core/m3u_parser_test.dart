import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_app/core/utils/m3u_parser.dart';

void main() {
  group('M3uParser', () {
    test('parses valid M3U content with all attributes', () {
      const content = '''#EXTM3U
#EXTINF:-1 tvg-id="bbc1.uk" tvg-name="BBC One" tvg-logo="https://example.com/bbc1.png" group-title="UK",BBC One HD
http://stream.example.com/bbc1
#EXTINF:-1 tvg-id="cnn.us" tvg-name="CNN" tvg-logo="https://example.com/cnn.png" group-title="News",CNN International
http://stream.example.com/cnn
''';

      final channels = M3uParser.parse(content);

      expect(channels.length, 2);

      expect(channels[0].name, 'BBC One');
      expect(channels[0].tvgId, 'bbc1.uk');
      expect(channels[0].logoUrl, 'https://example.com/bbc1.png');
      expect(channels[0].category, 'UK');
      expect(channels[0].streamUrl, 'http://stream.example.com/bbc1');

      expect(channels[1].name, 'CNN');
      expect(channels[1].category, 'News');
    });

    test('parses M3U with missing attributes', () {
      const content = '''#EXTM3U
#EXTINF:-1,Channel One
http://stream.example.com/ch1
#EXTINF:-1 group-title="Sports",ESPN
http://stream.example.com/espn
''';

      final channels = M3uParser.parse(content);

      expect(channels.length, 2);
      expect(channels[0].name, 'Channel One');
      expect(channels[0].category, 'Uncategorized');
      expect(channels[0].logoUrl, '');
      expect(channels[1].name, 'ESPN');
      expect(channels[1].category, 'Sports');
    });

    test('handles empty content', () {
      final channels = M3uParser.parse('');
      expect(channels, isEmpty);
    });

    test('handles content with no valid channels', () {
      const content = '''#EXTM3U
# Just comments
# No actual channels
''';

      final channels = M3uParser.parse(content);
      expect(channels, isEmpty);
    });

    test('handles Windows-style line endings', () {
      const content =
          '#EXTM3U\r\n#EXTINF:-1,Test Channel\r\nhttp://stream.example.com/test\r\n';

      final channels = M3uParser.parse(content);
      expect(channels.length, 1);
      expect(channels[0].name, 'Test Channel');
    });

    test('skips malformed entries without crashing', () {
      const content = '''#EXTM3U
#EXTINF:-1,Good Channel
http://stream.example.com/good
#EXTINF:
http://stream.example.com/bad
#EXTINF:-1,Another Good Channel
http://stream.example.com/good2
''';

      final channels = M3uParser.parse(content);
      expect(channels.length, 3);
    });

    test('handles large playlist parsing', () {
      final buffer = StringBuffer('#EXTM3U\n');
      for (var i = 0; i < 1000; i++) {
        buffer.writeln(
            '#EXTINF:-1 tvg-id="ch$i" group-title="Group ${i % 10}",Channel $i');
        buffer.writeln('http://stream.example.com/ch$i');
      }

      final channels = M3uParser.parse(buffer.toString());
      expect(channels.length, 1000);
    });
  });
}
