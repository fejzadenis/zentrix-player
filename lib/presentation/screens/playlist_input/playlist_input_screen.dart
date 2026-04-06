import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/channel_provider.dart';
import '../../providers/playlist_provider.dart';

class PlaylistInputScreen extends ConsumerStatefulWidget {
  const PlaylistInputScreen({super.key});

  @override
  ConsumerState<PlaylistInputScreen> createState() =>
      _PlaylistInputScreenState();
}

class _PlaylistInputScreenState extends ConsumerState<PlaylistInputScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _m3uUrlController = TextEditingController();
  final _m3uNameController = TextEditingController();
  final _xtreamServerController = TextEditingController();
  final _xtreamUsernameController = TextEditingController();
  final _xtreamPasswordController = TextEditingController();
  final _xtreamNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _m3uUrlController.dispose();
    _m3uNameController.dispose();
    _xtreamServerController.dispose();
    _xtreamUsernameController.dispose();
    _xtreamPasswordController.dispose();
    _xtreamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadM3uUrl() async {
    final l = AppLocalizations.of(context);
    final url = _m3uUrlController.text.trim();
    if (url.isEmpty) {
      _showError(l.enterValidUrl);
      return;
    }

    final channels = await ref
        .read(playlistProvider.notifier)
        .loadM3uUrl(url, _m3uNameController.text.trim());

    if (channels.isNotEmpty && mounted) {
      await ref.read(channelProvider.notifier).setChannels(channels);
      if (mounted) context.go('/home');
    }
  }

  Future<void> _loadM3uFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8'],
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    final channels = await ref
        .read(playlistProvider.notifier)
        .loadM3uFile(path, result.files.first.name);

    if (channels.isNotEmpty && mounted) {
      await ref.read(channelProvider.notifier).setChannels(channels);
      if (mounted) context.go('/home');
    }
  }

  Future<void> _loadXtreamCodes() async {
    final l = AppLocalizations.of(context);
    final server = _xtreamServerController.text.trim();
    final username = _xtreamUsernameController.text.trim();
    final password = _xtreamPasswordController.text.trim();

    if (server.isEmpty || username.isEmpty || password.isEmpty) {
      _showError(l.fillAllFields);
      return;
    }

    final channels = await ref
        .read(playlistProvider.notifier)
        .loadXtreamCodes(server, username, password, _xtreamNameController.text.trim());

    if (channels.isNotEmpty && mounted) {
      await ref.read(channelProvider.notifier).setChannels(channels);
      if (mounted) context.go('/home');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistProvider);
    final l = AppLocalizations.of(context);

    ref.listen<PlaylistState>(playlistProvider, (prev, next) {
      if (next.error != null) {
        _showError(next.error!);
        ref.read(playlistProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                l.addPlaylist,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l.choosePlaylistMethod,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.primaryGradient,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: l.m3uUrl),
                    Tab(text: l.file),
                    Tab(text: l.xtream),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildM3uUrlTab(l),
                    _buildFileTab(l),
                    _buildXtreamTab(l),
                  ],
                ),
              ),
              if (playlistState.playlists.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSavedPlaylists(playlistState, l),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildM3uUrlTab(AppLocalizations l) {
    final isLoading = ref.watch(playlistProvider).isLoading;
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _m3uNameController,
            decoration: InputDecoration(
              labelText: l.playlistName,
              hintText: l.playlistNameHint,
              prefixIcon: const Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _m3uUrlController,
            decoration: InputDecoration(
              labelText: l.m3uUrl,
              hintText: l.m3uUrlHint,
              prefixIcon: const Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),
          _buildLoadButton(l.loadPlaylist, _loadM3uUrl, isLoading),
        ],
      ),
    );
  }

  Widget _buildFileTab(AppLocalizations l) {
    final isLoading = ref.watch(playlistProvider).isLoading;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.upload_file_rounded,
                  size: 64,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  l.importM3uFile,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l.supportsM3u,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLoadButton(l.chooseFile, _loadM3uFile, isLoading),
        ],
      ),
    );
  }

  Widget _buildXtreamTab(AppLocalizations l) {
    final isLoading = ref.watch(playlistProvider).isLoading;
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _xtreamNameController,
            decoration: InputDecoration(
              labelText: l.playlistName,
              hintText: l.playlistNameHint,
              prefixIcon: const Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamServerController,
            decoration: InputDecoration(
              labelText: l.serverUrl,
              hintText: l.serverUrlHint,
              prefixIcon: const Icon(Icons.dns_outlined),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamUsernameController,
            decoration: InputDecoration(
              labelText: l.username,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamPasswordController,
            decoration: InputDecoration(
              labelText: l.password,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          _buildLoadButton(l.connect, _loadXtreamCodes, isLoading),
        ],
      ),
    );
  }

  Widget _buildLoadButton(String text, VoidCallback onPressed, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSavedPlaylists(PlaylistState state, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.savedPlaylists,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.playlists.length,
            itemBuilder: (context, index) {
              final playlist = state.playlists[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => _loadSavedPlaylist(playlist),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.channelCount(playlist.channelCount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadSavedPlaylist(playlist) async {
    final notifier = ref.read(playlistProvider.notifier);
    List channels;

    switch (playlist.type) {
      case 0:
        channels = await notifier.loadM3uUrl(playlist.url, playlist.name);
        break;
      case 2:
        channels = await notifier.loadXtreamCodes(
          playlist.serverUrl ?? '',
          playlist.username ?? '',
          playlist.password ?? '',
          playlist.name,
        );
        break;
      default:
        channels = [];
    }

    if (channels.isNotEmpty && mounted) {
      await ref.read(channelProvider.notifier).setChannels(
        channels.cast(),
      );
      if (mounted) context.go('/home');
    }
  }
}
