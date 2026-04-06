import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/player_provider.dart';
import '../../widgets/player_controls.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String streamUrl;
  final String channelName;
  final String channelId;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.channelName,
    this.channelId = '',
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  bool _showControls = true;
  Timer? _hideTimer;
  bool _isFullscreen = false;
  int _reconnectAttempts = 0;
  bool _isBuffering = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;
  final List<String> _debugLog = [];
  bool _showDebug = false;
  static const int _maxReconnectAttempts = 3;

  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _completedSub;

  void _log(String message) {
    dev.log('[IPTV Player] $message');
    if (mounted) {
      setState(() {
        _debugLog.add(
            '[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
        if (_debugLog.length > 50) _debugLog.removeAt(0);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _startHideTimer();

    _log('Channel: ${widget.channelName}');
    _log('Stream URL: ${widget.streamUrl}');

    _player = Player();
    _videoController = VideoController(_player);

    _setupListeners();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(playerProvider.notifier).setChannel(
            widget.channelId,
            widget.channelName,
            widget.streamUrl,
          );
    });

    _initPlayer();
  }

  void _setupListeners() {
    _playingSub = _player.stream.playing.listen((playing) {
      if (!mounted) return;
      _log('Playing: $playing');
      setState(() => _isPlaying = playing);
    });

    _bufferingSub = _player.stream.buffering.listen((buffering) {
      if (!mounted) return;
      if (buffering) _log('Buffering...');
      setState(() => _isBuffering = buffering);
    });

    _errorSub = _player.stream.error.listen((error) {
      if (!mounted) return;
      _log('ERROR from player: $error');
      setState(() {
        _hasError = true;
        _errorMessage = error;
      });
      _attemptReconnect();
    });

    _completedSub = _player.stream.completed.listen((completed) {
      if (!mounted || !completed) return;
      _log('Stream completed, attempting reconnect...');
      _attemptReconnect();
    });
  }

  Future<void> _initPlayer() async {
    _log('Initializing player (attempt ${_reconnectAttempts + 1})...');

    final url = widget.streamUrl;
    if (url.isEmpty) {
      _log('ERROR: Stream URL is empty!');
      setState(() {
        _hasError = true;
        _isBuffering = false;
        _errorMessage = 'Stream URL is empty';
      });
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _log('ERROR: Invalid URL format: $url');
      setState(() {
        _hasError = true;
        _isBuffering = false;
        _errorMessage = 'Invalid URL: $url';
      });
      return;
    }

    _log('Opening media: scheme=${uri.scheme}, host=${uri.host}');

    setState(() {
      _isBuffering = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await _player.open(
        Media(url, httpHeaders: {'User-Agent': 'Zentrix/1.0'}),
      );
      _log('Media opened successfully');
    } catch (e, stack) {
      _log('ERROR opening media: $e');
      _log('Stack: ${stack.toString().split('\n').take(3).join(' | ')}');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isBuffering = false;
        _errorMessage = e.toString();
      });
      _attemptReconnect();
    }
  }

  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('Max reconnect attempts reached ($_maxReconnectAttempts)');
      return;
    }
    _reconnectAttempts++;
    final delaySec = _reconnectAttempts * 2;
    _log('Reconnecting in ${delaySec}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)...');
    setState(() {
      _isBuffering = true;
      _hasError = false;
    });

    await Future.delayed(Duration(seconds: delaySec));
    if (mounted) {
      _initPlayer();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _errorSub?.cancel();
    _completedSub?.cancel();
    _player.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTap: _toggleFullscreen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Video(
                controller: _videoController,
                fill: Colors.black,
              ),
            ),

            if (_isBuffering && !_hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _reconnectAttempts > 0
                          ? l.reconnecting(_reconnectAttempts, _maxReconnectAttempts)
                          : l.loadingStream,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

            if (_hasError && _reconnectAttempts >= _maxReconnectAttempts)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        l.streamUnavailable,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          'URL: ${widget.streamUrl}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _reconnectAttempts = 0;
                                _hasError = false;
                                _errorMessage = null;
                                _isBuffering = true;
                              });
                              _initPlayer();
                            },
                            icon: const Icon(Icons.refresh,
                                color: AppColors.primary),
                            label: Text(l.retry,
                                style: const TextStyle(color: AppColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _showDebug = !_showDebug),
                            icon: const Icon(Icons.bug_report,
                                color: Colors.amber),
                            label: Text(l.debugLog,
                                style: const TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_showDebug)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  color: Colors.black.withValues(alpha: 0.92),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Icon(Icons.bug_report,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            Text(l.debugLog,
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showDebug = false),
                              child: const Icon(Icons.close,
                                  color: Colors.white54, size: 20),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          reverse: true,
                          itemCount: _debugLog.length,
                          itemBuilder: (context, index) {
                            final entry =
                                _debugLog[_debugLog.length - 1 - index];
                            final isError = entry.contains('ERROR');
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 1),
                              child: Text(
                                entry,
                                style: TextStyle(
                                  color: isError
                                      ? Colors.redAccent
                                      : Colors.greenAccent
                                          .withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_showControls && !_showDebug)
              PlayerControls(
                channelName: widget.channelName,
                isPlaying: _isPlaying,
                isFullscreen: _isFullscreen,
                position: Duration.zero,
                duration: Duration.zero,
                onPlayPause: () {
                  _player.playOrPause();
                  _startHideTimer();
                },
                onFullscreen: _toggleFullscreen,
                onBack: () => Navigator.of(context).pop(),
              ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 20),
              ),
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _showDebug = !_showDebug),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _showDebug ? Colors.amber : Colors.white24,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bug_report,
                          size: 14,
                          color:
                              _showDebug ? Colors.amber : Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        'LOG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              _showDebug ? Colors.amber : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
