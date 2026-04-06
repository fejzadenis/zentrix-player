import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: l.appearance),
          const SizedBox(height: 8),
          _buildThemeCard(context, ref, settings, l),
          const SizedBox(height: 12),
          _buildLanguageCard(context, ref, settings, l),
          const SizedBox(height: 24),
          _SectionHeader(title: l.playback),
          const SizedBox(height: 8),
          _buildBufferCard(context, ref, settings, l),
          const SizedBox(height: 12),
          _buildUserAgentCard(context, ref, settings, l),
          const SizedBox(height: 24),
          _SectionHeader(title: l.playlists),
          const SizedBox(height: 8),
          _buildManagePlaylistsCard(context, l),
          const SizedBox(height: 24),
          _SectionHeader(title: l.about),
          const SizedBox(height: 8),
          _buildAboutCard(context, l),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations l,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.theme, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                _ThemeOption(
                  icon: Icons.dark_mode_rounded,
                  label: l.dark,
                  isSelected: settings.themeMode == ThemeMode.dark,
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(ThemeMode.dark),
                ),
                const SizedBox(width: 12),
                _ThemeOption(
                  icon: Icons.light_mode_rounded,
                  label: l.light,
                  isSelected: settings.themeMode == ThemeMode.light,
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(ThemeMode.light),
                ),
                const SizedBox(width: 12),
                _ThemeOption(
                  icon: Icons.brightness_auto_rounded,
                  label: l.system,
                  isSelected: settings.themeMode == ThemeMode.system,
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations l,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.language,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                _LanguageOption(
                  label: l.english,
                  flag: '🇬🇧',
                  isSelected: settings.language == 'en',
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setLanguage('en'),
                ),
                const SizedBox(width: 12),
                _LanguageOption(
                  label: l.serbian,
                  flag: '🇷🇸',
                  isSelected: settings.language == 'sr',
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setLanguage('sr'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferCard(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations l,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.bufferDuration,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${settings.bufferDurationMs ~/ 1000}s',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: settings.bufferDurationMs.toDouble(),
              min: AppConstants.minBufferMs.toDouble(),
              max: AppConstants.maxBufferMs.toDouble(),
              divisions: 9,
              activeColor: AppColors.primary,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setBufferDuration(value.toInt());
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppConstants.minBufferMs ~/ 1000}s',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${AppConstants.maxBufferMs ~/ 1000}s',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAgentCard(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations l,
  ) {
    return Card(
      child: ListTile(
        title: Text(l.userAgent),
        subtitle: Text(
          settings.userAgent,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.edit, size: 20),
        onTap: () => _showUserAgentDialog(context, ref, settings.userAgent, l),
      ),
    );
  }

  void _showUserAgentDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
    AppLocalizations l,
  ) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.customUserAgent),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l.enterCustomUserAgent,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setUserAgent(controller.text.trim());
              Navigator.pop(context);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  Widget _buildManagePlaylistsCard(BuildContext context, AppLocalizations l) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.playlist_play_rounded),
        title: Text(l.managePlaylists),
        subtitle: Text(l.managePlaylistsDesc),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/playlist-input'),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, AppLocalizations l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.appName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${l.version} ${AppConstants.appVersion}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l.aboutDesc,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 1,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
