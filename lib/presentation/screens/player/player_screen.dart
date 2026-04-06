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
  static const int _maxReconnectAttempts = 3;

  // Volume & brightness
  double _volume = 1.0;
  double _brightness = 0.5;
  bool _showVolumeSlider = false;
  bool _showBrightnessSlider = false;
  Timer? _sliderHideTimer;

  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _completedSub;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _startHideTimer();

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
      _attemptReconnect();
    });

    _player.stream.volume.listen((vol) {
      if (!mounted) return;
      setState(() => _volume = vol / 100.0);
    });
  }

  Future<void> _initPlayer() async {
    final url = widget.streamUrl;
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

  @override
  void dispose() {
    _hideTimer?.cancel();
    _sliderHideTimer?.cancel();
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
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTap: _toggleFullscreen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video
            Center(
              child: Video(
                controller: _videoController,
                fill: Colors.black,
              ),
            ),

            // Buffering indicator
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

            // Error state
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

            // Controls overlay
            if (_showControls)
              _buildControlsOverlay(context, l, topPad),

            // Brightness slider — left side
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

            // Volume slider — right side
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
            // Top bar: back + channel info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                    iconSize: 22,
                  ),
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
                          widget.channelName,
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
                ],
              ),
            ),

            const Spacer(),

            // Bottom bar: brightness, fullscreen, volume
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
                    icon: _isFullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    onTap: _toggleFullscreen,
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

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
