import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/channel.dart';
import '../../providers/channel_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';

enum AspectMode { fit, fill, stretch }

class PlayerScreen extends ConsumerStatefulWidget {
  final String streamUrl;
  final String channelName;
  final String channelId;
  final List<Channel>? channelList;
  final int currentIndex;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.channelName,
    this.channelId = '',
    this.channelList,
    this.currentIndex = -1,
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
  static const int _maxReconnectAttempts = 3;

  double _volume = 1.0;
  double _brightness = 0.5;
  bool _showVolumeSlider = false;
  bool _showBrightnessSlider = false;
  Timer? _sliderHideTimer;

  AspectMode _aspectMode = AspectMode.fit;
  double _playbackSpeed = 1.0;

  Channel? _nextEpisode;
  bool _showNextEpisode = false;
  Timer? _autoPlayTimer;
  int _autoPlayCountdown = 10;

  final SimplePip _simplePip = SimplePip();
  bool _isPipAvailable = false;

  // Channel zapping
  late String _currentStreamUrl;
  late String _currentChannelName;
  late String _currentChannelId;
  ContentType _currentContentType = ContentType.live;
  List<Channel>? _channelList;
  int _currentIndex = -1;
  String? _lastChannelId;
  String? _lastStreamUrl;
  String? _lastChannelName;

  // Resume playback
  StreamSubscription? _positionSub;
  bool _hasResumed = false;

  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _tracksSub;

  Tracks _tracks = const Tracks();

  @override
  void initState() {
    super.initState();
    _currentStreamUrl = widget.streamUrl;
    _currentChannelName = widget.channelName;
    _currentChannelId = widget.channelId;
    _channelList = widget.channelList;
    _currentIndex = widget.currentIndex;

    if (_channelList != null && _currentIndex >= 0 && _currentIndex < _channelList!.length) {
      _currentContentType = _channelList![_currentIndex].contentType;
    }

    WakelockPlus.enable();
    _startHideTimer();

    _player = Player();
    _videoController = VideoController(_player);

    _setupListeners();
    _checkPipAvailability();

    Future.microtask(() {
      if (!mounted) return;
      final storage = ref.read(localStorageProvider);
      storage.recordWatch(_currentChannelId);
      ref.read(playerProvider.notifier).setChannel(
            _currentChannelId,
            _currentChannelName,
            _currentStreamUrl,
          );
      _checkResume(storage);
    });

    _initPlayer();
  }

  void _checkResume(dynamic storage) {
    if (_hasResumed) return;
    if (_currentContentType == ContentType.live) return;
    final entry = storage.getWatchEntry(_currentChannelId);
    if (entry == null) return;
    final posMs = entry['lastPositionMs'] as int? ?? 0;
    if (posMs <= 5000) return;

    _hasResumed = true;
    final pos = Duration(milliseconds: posMs);
    final formatted = '${pos.inMinutes}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}';
    final l = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.resumeFrom(formatted)),
        action: SnackBarAction(
          label: l.resumePlayback,
          onPressed: () => _player.seek(pos),
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setupListeners() {
    _playingSub = _player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() {});
    });

    _bufferingSub = _player.stream.buffering.listen((buffering) {
      if (!mounted) return;
      setState(() => _isBuffering = buffering);
    });

    _errorSub = _player.stream.error.listen((error) {
      if (!mounted) return;
      dev.log('[Zentrix Player] ERROR: $error');
      setState(() {
        _hasError = true;
        _errorMessage = error;
      });
      _attemptReconnect();
    });

    _completedSub = _player.stream.completed.listen((completed) {
      if (!mounted || !completed) return;
      _checkAutoPlayNext();
    });

    _player.stream.volume.listen((vol) {
      if (!mounted) return;
      setState(() => _volume = vol / 100.0);
    });

    _tracksSub = _player.stream.tracks.listen((tracks) {
      if (!mounted) return;
      setState(() => _tracks = tracks);
    });

    _positionSub = _player.stream.position.listen((position) {
      if (!mounted || _currentChannelId.isEmpty) return;
      if (_currentContentType == ContentType.live) return;
      if (position.inSeconds > 0 && position.inSeconds % 5 == 0) {
        final storage = ref.read(localStorageProvider);
        storage.updateWatchPosition(_currentChannelId, position.inMilliseconds);
      }
    });
  }

  Future<void> _initPlayer() async {
    final url = _currentStreamUrl;
    if (url.isEmpty) {
      setState(() {
        _hasError = true;
        _isBuffering = false;
        _errorMessage = 'Stream URL is empty';
      });
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      setState(() {
        _hasError = true;
        _isBuffering = false;
        _errorMessage = 'Invalid URL: $url';
      });
      return;
    }

    setState(() {
      _isBuffering = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await _player.open(
        Media(url, httpHeaders: {'User-Agent': 'Zentrix/1.0'}),
      );
    } catch (e) {
      dev.log('[Zentrix Player] ERROR opening media: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isBuffering = false;
        _errorMessage = e.toString();
      });
      _attemptReconnect();
    }
  }

  void _zapChannel(int direction) {
    if (_channelList == null || _channelList!.isEmpty) return;
    final list = _channelList!;
    int newIndex = _currentIndex + direction;
    if (newIndex < 0) newIndex = list.length - 1;
    if (newIndex >= list.length) newIndex = 0;

    final newChannel = list[newIndex];
    _switchToChannel(newChannel, newIndex);
  }

  void _switchToChannel(Channel channel, [int? index]) {
    _lastChannelId = _currentChannelId;
    _lastStreamUrl = _currentStreamUrl;
    _lastChannelName = _currentChannelName;

    setState(() {
      _currentStreamUrl = channel.streamUrl;
      _currentChannelName = channel.name;
      _currentChannelId = channel.id;
      _currentContentType = channel.contentType;
      if (index != null) _currentIndex = index;
      _reconnectAttempts = 0;
      _hasError = false;
      _hasResumed = false;
    });

    final storage = ref.read(localStorageProvider);
    storage.recordWatch(channel.id);
    ref.read(playerProvider.notifier).setChannel(
          channel.id, channel.name, channel.streamUrl);

    _initPlayer();
  }

  void _toggleLastChannel() {
    if (_lastChannelId == null || _lastStreamUrl == null) return;
    final tempChannel = Channel(
      id: _lastChannelId!,
      name: _lastChannelName ?? '',
      streamUrl: _lastStreamUrl!,
    );
    _switchToChannel(tempChannel);
  }

  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    final delaySec = _reconnectAttempts * 2;
    setState(() {
      _isBuffering = true;
      _hasError = false;
    });
    await Future.delayed(Duration(seconds: delaySec));
    if (mounted) _initPlayer();
  }

  Future<void> _checkPipAvailability() async {
    try {
      final available = await SimplePip.isPipAvailable;
      if (mounted) setState(() => _isPipAvailable = available);
    } catch (_) {
      // PiP not supported on this platform
    }
  }

  Future<void> _enterPip() async {
    if (!_isPipAvailable) return;
    try {
      await _simplePip.enterPipMode();
    } catch (e) {
      dev.log('[Zentrix Player] PiP error: $e');
    }
  }

  void _checkAutoPlayNext() {
    final next = ref.read(channelProvider.notifier).getNextEpisode(widget.channelId);
    if (next != null) {
      setState(() {
        _nextEpisode = next;
        _showNextEpisode = true;
        _autoPlayCountdown = 10;
      });
      _autoPlayTimer?.cancel();
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _autoPlayCountdown--);
        if (_autoPlayCountdown <= 0) {
          timer.cancel();
          _playNextEpisode();
        }
      });
    } else {
      _attemptReconnect();
    }
  }

  void _playNextEpisode() {
    _autoPlayTimer?.cancel();
    final next = _nextEpisode;
    if (next == null || !mounted) return;

    Navigator.of(context).pop();
    context.push('/player', extra: {
      'streamUrl': next.streamUrl,
      'channelName': next.name,
      'channelId': next.id,
    });
  }

  void _cancelAutoPlay() {
    _autoPlayTimer?.cancel();
    setState(() => _showNextEpisode = false);
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
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _setVolume(double v) {
    final clamped = v.clamp(0.0, 1.0);
    _player.setVolume(clamped * 100);
    setState(() => _volume = clamped);
    _resetSliderTimer();
  }

  void _setBrightness(double b) {
    setState(() => _brightness = b.clamp(0.0, 1.0));
    _resetSliderTimer();
  }

  void _resetSliderTimer() {
    _sliderHideTimer?.cancel();
    _sliderHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showVolumeSlider = false;
          _showBrightnessSlider = false;
        });
      }
    });
  }

  void _cycleAspect() {
    setState(() {
      const values = AspectMode.values;
      _aspectMode = values[(_aspectMode.index + 1) % values.length];
    });
  }

  void _cycleSpeed() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final idx = speeds.indexOf(_playbackSpeed);
    final next = speeds[(idx + 1) % speeds.length];
    _player.setRate(next);
    setState(() => _playbackSpeed = next);
  }

  Future<void> _openExternal() async {
    final url = _currentStreamUrl;
    final vlcUrl = 'vlc://$url';
    final uri = Uri.parse(vlcUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final fallback = Uri.parse(url);
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  void _showAudioTrackPicker() {
    final l = AppLocalizations.of(context);
    final audioTracks = _tracks.audio;
    if (audioTracks.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l.audioTrack,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...audioTracks.map((track) {
                final isActive = track == _tracks.audio.firstOrNull;
                final title = track.title ?? track.language ?? track.id;
                return ListTile(
                  leading: Icon(
                    Icons.audiotrack_rounded,
                    color: isActive ? AppColors.primary : Colors.white54,
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? AppColors.primary : Colors.white,
                    ),
                  ),
                  onTap: () {
                    _player.setAudioTrack(track);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showSubtitleTrackPicker() {
    final l = AppLocalizations.of(context);
    final subTracks = _tracks.subtitle;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l.subtitleTrack,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.subtitles_off_rounded, color: Colors.white54),
                title: Text(l.off, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  _player.setSubtitleTrack(SubtitleTrack.no());
                  Navigator.pop(ctx);
                },
              ),
              ...subTracks.map((track) {
                final title = track.title ?? track.language ?? track.id;
                return ListTile(
                  leading: const Icon(Icons.subtitles_rounded, color: Colors.white54),
                  title: Text(
                    title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    _player.setSubtitleTrack(track);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showPlayerMenu() {
    final l = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _MenuTile(
                icon: Icons.audiotrack_rounded,
                title: l.audioTrack,
                subtitle: '${_tracks.audio.length} tracks',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAudioTrackPicker();
                },
              ),
              _MenuTile(
                icon: Icons.subtitles_rounded,
                title: l.subtitleTrack,
                subtitle: _tracks.subtitle.isEmpty ? l.noSubtitleTracks : '${_tracks.subtitle.length} tracks',
                onTap: () {
                  Navigator.pop(ctx);
                  _showSubtitleTrackPicker();
                },
              ),
              _MenuTile(
                icon: Icons.aspect_ratio_rounded,
                title: l.aspectRatio,
                subtitle: _aspectLabel(l),
                onTap: () {
                  Navigator.pop(ctx);
                  _cycleAspect();
                },
              ),
              _MenuTile(
                icon: Icons.speed_rounded,
                title: l.playbackSpeed,
                subtitle: '${_playbackSpeed}x',
                onTap: () {
                  Navigator.pop(ctx);
                  _cycleSpeed();
                },
              ),
              _MenuTile(
                icon: Icons.open_in_new_rounded,
                title: l.openExternal,
                onTap: () {
                  Navigator.pop(ctx);
                  _openExternal();
                },
              ),
              if (_isPipAvailable)
                _MenuTile(
                  icon: Icons.picture_in_picture_alt_rounded,
                  title: l.pipMode,
                  onTap: () {
                    Navigator.pop(ctx);
                    _enterPip();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _aspectLabel(AppLocalizations l) {
    switch (_aspectMode) {
      case AspectMode.fit:
        return l.fit;
      case AspectMode.fill:
        return l.fill;
      case AspectMode.stretch:
        return l.stretch;
    }
  }

  BoxFit get _videoFit {
    switch (_aspectMode) {
      case AspectMode.fit:
        return BoxFit.contain;
      case AspectMode.fill:
        return BoxFit.cover;
      case AspectMode.stretch:
        return BoxFit.fill;
    }
  }

  static Widget _noControls(VideoState state) => const SizedBox.shrink();

  @override
  void dispose() {
    _hideTimer?.cancel();
    _sliderHideTimer?.cancel();
    _autoPlayTimer?.cancel();
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _errorSub?.cancel();
    _completedSub?.cancel();
    _tracksSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTap: _toggleFullscreen,
        onVerticalDragEnd: _channelList != null ? (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -300) {
            _zapChannel(1);
          } else if (velocity > 300) {
            _zapChannel(-1);
          }
        } : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _aspectMode == AspectMode.fit
                  ? Video(controller: _videoController, fill: Colors.black, controls: _noControls)
                  : FittedBox(
                      fit: _videoFit,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: Video(controller: _videoController, fill: Colors.black, controls: _noControls),
                      ),
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
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
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
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
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
                      const SizedBox(height: 16),
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
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        label: Text(l.retry,
                            style: const TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),

            // Back button — always visible
            Positioned(
              top: topPad + 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            if (_showControls)
              _buildControlsOverlay(context, l, topPad),

            if (_showBrightnessSlider)
              Positioned(
                left: 24,
                top: screenH * 0.2,
                bottom: screenH * 0.2,
                child: _VerticalSlider(
                  value: _brightness,
                  icon: _brightness > 0.5
                      ? Icons.brightness_high_rounded
                      : Icons.brightness_low_rounded,
                  activeColor: Colors.amber,
                  onChanged: _setBrightness,
                ),
              ),

            if (_showVolumeSlider)
              Positioned(
                right: 24,
                top: screenH * 0.2,
                bottom: screenH * 0.2,
                child: _VerticalSlider(
                  value: _volume,
                  icon: _volume == 0
                      ? Icons.volume_off_rounded
                      : _volume < 0.5
                          ? Icons.volume_down_rounded
                          : Icons.volume_up_rounded,
                  activeColor: AppColors.primary,
                  onChanged: _setVolume,
                ),
              ),

            if (_showNextEpisode && _nextEpisode != null)
              Positioned(
                bottom: 80,
                left: 24,
                right: 24,
                child: _NextEpisodeCard(
                  episodeName: _nextEpisode!.name,
                  countdown: _autoPlayCountdown,
                  onPlay: _playNextEpisode,
                  onCancel: _cancelAutoPlay,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(BuildContext context, AppLocalizations l, double topPad) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
          stops: const [0.0, 0.25, 0.75, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.live,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.live,
                              style: const TextStyle(
                                color: AppColors.live,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentChannelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_lastChannelId != null)
                    GestureDetector(
                      onTap: _toggleLastChannel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              l.lastChannel,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_playbackSpeed != 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_playbackSpeed}x',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ControlButton(
                    icon: Icons.brightness_6_rounded,
                    onTap: () {
                      setState(() {
                        _showBrightnessSlider = !_showBrightnessSlider;
                        _showVolumeSlider = false;
                      });
                      if (_showBrightnessSlider) _resetSliderTimer();
                    },
                    isActive: _showBrightnessSlider,
                  ),
                  _ControlButton(
                    icon: Icons.aspect_ratio_rounded,
                    onTap: _cycleAspect,
                    label: _aspectMode.name.toUpperCase(),
                  ),
                  _ControlButton(
                    icon: _isFullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    onTap: _toggleFullscreen,
                  ),
                  _ControlButton(
                    icon: Icons.more_vert_rounded,
                    onTap: _showPlayerMenu,
                  ),
                  _ControlButton(
                    icon: _volume == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    onTap: () {
                      setState(() {
                        _showVolumeSlider = !_showVolumeSlider;
                        _showBrightnessSlider = false;
                      });
                      if (_showVolumeSlider) _resetSliderTimer();
                    },
                    isActive: _showVolumeSlider,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: Colors.white38, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final String? label;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.6))
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          if (label != null) ...[
            const SizedBox(height: 3),
            Text(
              label!,
              style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerticalSlider extends StatelessWidget {
  final double value;
  final IconData icon;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _VerticalSlider({
    required this.value,
    required this.icon,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: activeColor, size: 20),
          const SizedBox(height: 8),
          Text(
            '${(value * 100).round()}',
            style: TextStyle(
              color: activeColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackHeight = constraints.maxHeight;
                return GestureDetector(
                  onVerticalDragUpdate: (details) {
                    final newVal = value - (details.delta.dy / trackHeight);
                    onChanged(newVal.clamp(0.0, 1.0));
                  },
                  onTapDown: (details) {
                    final tapVal = 1.0 - (details.localPosition.dy / trackHeight);
                    onChanged(tapVal.clamp(0.0, 1.0));
                  },
                  child: Container(
                    width: 44,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 4,
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: activeColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NextEpisodeCard extends StatelessWidget {
  final String episodeName;
  final int countdown;
  final VoidCallback onPlay;
  final VoidCallback onCancel;

  const _NextEpisodeCard({
    required this.episodeName,
    required this.countdown,
    required this.onPlay,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.skip_next_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.nextEpisode,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  episodeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.autoPlayNext(countdown),
                  style: const TextStyle(color: AppColors.primary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onPlay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
