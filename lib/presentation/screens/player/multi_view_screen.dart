import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/channel.dart';

class _PlayerSlot {
  final Channel channel;
  final Player player;
  final VideoController controller;
  StreamSubscription? bufferingSub;
  StreamSubscription? errorSub;
  bool isBuffering = true;
  bool hasError = false;

  _PlayerSlot({
    required this.channel,
    required this.player,
    required this.controller,
  });

  Future<void> dispose() async {
    await bufferingSub?.cancel();
    await errorSub?.cancel();
    await player.dispose();
  }
}

class MultiViewScreen extends StatefulWidget {
  final List<Channel> channels;

  const MultiViewScreen({
    super.key,
    required this.channels,
  }) : assert(channels.length >= 2 && channels.length <= 4);

  @override
  State<MultiViewScreen> createState() => _MultiViewScreenState();
}

class _MultiViewScreenState extends State<MultiViewScreen> {
  final List<_PlayerSlot> _slots = [];
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initPlayers();
  }

  void _initPlayers() {
    for (var i = 0; i < widget.channels.length; i++) {
      final channel = widget.channels[i];
      final player = Player();
      final controller = VideoController(player);
      final slot = _PlayerSlot(
        channel: channel,
        player: player,
        controller: controller,
      );

      slot.bufferingSub = player.stream.buffering.listen((buffering) {
        if (!mounted) return;
        setState(() => slot.isBuffering = buffering);
      });

      slot.errorSub = player.stream.error.listen((error) {
        if (!mounted) return;
        setState(() => slot.hasError = true);
      });

      _slots.add(slot);

      player.setVolume(i == _focusedIndex ? 100.0 : 0.0);
      player.open(
        Media(channel.streamUrl, httpHeaders: {'User-Agent': 'Zentrix/1.0'}),
      );
    }
  }

  void _setFocus(int index) {
    if (index == _focusedIndex || index >= _slots.length) return;
    setState(() {
      _focusedIndex = index;
    });
    for (var i = 0; i < _slots.length; i++) {
      _slots[i].player.setVolume(i == _focusedIndex ? 100.0 : 0.0);
    }
  }

  Future<void> _closeSlot(int index) async {
    if (_slots.length <= 1) {
      Navigator.of(context).pop();
      return;
    }

    final slot = _slots.removeAt(index);
    await slot.dispose();

    if (_focusedIndex >= _slots.length) {
      _focusedIndex = _slots.length - 1;
    }
    for (var i = 0; i < _slots.length; i++) {
      _slots[i].player.setVolume(i == _focusedIndex ? 100.0 : 0.0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      slot.dispose();
    }
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          Positioned.fill(child: _buildGrid()),
          Positioned(
            top: topPad + 4,
            left: 4,
            child: _BackButton(onTap: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final count = _slots.length;
    switch (count) {
      case 1:
        return _buildTile(0);
      case 2:
        return Row(
          children: [
            Expanded(child: _buildTile(0)),
            const SizedBox(width: 2),
            Expanded(child: _buildTile(1)),
          ],
        );
      case 3:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildTile(0)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildTile(1)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(child: _buildTile(2)),
          ],
        );
      case 4:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildTile(0)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildTile(1)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildTile(2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildTile(3)),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTile(int index) {
    final slot = _slots[index];
    final isFocused = index == _focusedIndex;

    return GestureDetector(
      onTap: () => _setFocus(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused
                ? AppColors.primary.withValues(alpha: 0.8)
                : Colors.transparent,
            width: isFocused ? 2.0 : 0.0,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),

            Video(
              controller: slot.controller,
              fill: Colors.black,
              controls: NoVideoControls,
            ),

            if (slot.isBuffering && !slot.hasError)
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              ),

            if (slot.hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'Stream unavailable',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

            // Channel name bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    if (isFocused)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        slot.channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isFocused ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isFocused ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 4,
              right: 4,
              child: _CloseButton(onTap: () => _closeSlot(index)),
            ),
          ],
        ),
      ),
    );
  }
}

Widget NoVideoControls(VideoState state) {
  return const SizedBox.shrink();
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.white70,
          size: 16,
        ),
      ),
    );
  }
}
