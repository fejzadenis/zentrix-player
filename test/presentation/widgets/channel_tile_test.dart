import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentrix/domain/entities/channel.dart';
import 'package:zentrix/presentation/widgets/channel_tile.dart';

void main() {
  group('ChannelTile', () {
    testWidgets('displays channel name and category', (tester) async {
      const channel = Channel(
        id: 'test_1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream',
        category: 'Entertainment',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelTile(
              channel: channel,
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Channel'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
    });

    testWidgets('shows LIVE indicator for live channels', (tester) async {
      const channel = Channel(
        id: 'test_1',
        name: 'Live Channel',
        streamUrl: 'http://example.com/stream',
        isLive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelTile(
              channel: channel,
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('shows filled heart when favorited', (tester) async {
      const channel = Channel(
        id: 'test_1',
        name: 'Fav Channel',
        streamUrl: 'http://example.com/stream',
        isFavorite: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelTile(
              channel: channel,
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('shows outline heart when not favorited', (tester) async {
      const channel = Channel(
        id: 'test_1',
        name: 'Normal Channel',
        streamUrl: 'http://example.com/stream',
        isFavorite: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelTile(
              channel: channel,
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      var tapped = false;
      const channel = Channel(
        id: 'test_1',
        name: 'Tappable Channel',
        streamUrl: 'http://example.com/stream',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelTile(
              channel: channel,
              onTap: () => tapped = true,
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Channel'));
      expect(tapped, true);
    });

    testWidgets('displays current program when provided', (tester) async {
      const channel = Channel(
        id: 'test_1',
        name: 'EPG Channel',
        streamUrl: 'http://example.com/stream',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelTile(
              channel: channel,
              currentProgram: 'News at 9',
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('News at 9'), findsOneWidget);
    });
  });
}
