import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../providers/channel_provider.dart';

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
          _SectionHeader(title: l.parentalLock),
          const SizedBox(height: 8),
          _buildParentalCard(context, ref, settings, l),
          const SizedBox(height: 12),
          _buildHiddenCategoriesCard(context, ref, settings, l),
          const SizedBox(height: 24),
          _SectionHeader(title: l.playlists),
          const SizedBox(height: 8),
          _buildManagePlaylistsCard(context, l),
          const SizedBox(height: 24),
          _SectionHeader(title: l.deviceInfo),
          const SizedBox(height: 8),
          _MacAddressCard(),
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

  Widget _buildParentalCard(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.parentalLock, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        l.parentalLockDesc,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.parentalEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (enabled) {
                    if (enabled && settings.parentalPin.isEmpty) {
                      _showSetPinDialog(context, ref, l);
                    } else if (enabled) {
                      ref.read(settingsProvider.notifier).enableParental(true);
                    } else {
                      _showVerifyPinDialog(context, ref, l, () {
                        ref.read(settingsProvider.notifier).enableParental(false);
                      });
                    }
                  },
                ),
              ],
            ),
            if (settings.parentalEnabled) ...[
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                title: Text(l.setPin),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  _showVerifyPinDialog(context, ref, l, () {
                    _showSetPinDialog(context, ref, l);
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenCategoriesCard(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations l,
  ) {
    final channelState = ref.watch(channelProvider);
    final allCategories = <String>{};
    for (final ch in channelState.channels) {
      if (ch.category.isNotEmpty && ch.category != 'Uncategorized') {
        allCategories.add(ch.category);
      }
    }
    final sortedCategories = allCategories.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.hiddenCategories, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              l.hiddenCategoriesDesc,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (sortedCategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sortedCategories.map((cat) {
                  final isHidden = settings.hiddenCategories.contains(cat);
                  return FilterChip(
                    selected: isHidden,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isHidden) ...[
                          const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(cat, style: TextStyle(fontSize: 12, color: isHidden ? Colors.white : null)),
                      ],
                    ),
                    selectedColor: AppColors.error.withValues(alpha: 0.7),
                    onSelected: (_) {
                      if (settings.parentalEnabled) {
                        ref.read(settingsProvider.notifier).toggleCategoryHidden(cat);
                        ref.read(channelProvider.notifier).applyHiddenFilter(
                          ref.read(hiddenCategoriesProvider),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.parentalLockDesc)),
                        );
                      }
                    },
                    showCheckmark: false,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSetPinDialog(BuildContext context, WidgetRef ref, AppLocalizations l) {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.setPin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(labelText: l.enterPin),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(labelText: l.confirmPin),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              if (pinCtrl.text.length < 4) return;
              if (pinCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.pinMismatch)),
                );
                return;
              }
              ref.read(settingsProvider.notifier).setParentalPin(pinCtrl.text);
              ref.read(settingsProvider.notifier).enableParental(true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.pinSet)),
              );
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _showVerifyPinDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    VoidCallback onSuccess,
  ) {
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.enterPin),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(labelText: l.enterCurrentPin),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              if (ref.read(settingsProvider.notifier).verifyPin(pinCtrl.text)) {
                Navigator.pop(ctx);
                onSuccess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.wrongPin)),
                );
              }
            },
            child: Text(l.unlock),
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

class _MacAddressCard extends StatefulWidget {
  @override
  State<_MacAddressCard> createState() => _MacAddressCardState();
}

class _MacAddressCardState extends State<_MacAddressCard> {
  String _macAddress = '...';

  @override
  void initState() {
    super.initState();
    _loadMac();
  }

  Future<void> _loadMac() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        if (iface.name.toLowerCase().contains('wi') ||
            iface.name.toLowerCase().contains('wlan') ||
            iface.name.toLowerCase().contains('eth') ||
            iface.name.toLowerCase().contains('en')) {
          final raw = iface.addresses.first.address;
          if (raw.isNotEmpty) {
            final mac = _extractMac(iface);
            if (mac != null) {
              setState(() => _macAddress = mac);
              return;
            }
          }
        }
      }
      if (interfaces.isNotEmpty) {
        final mac = _extractMac(interfaces.first);
        setState(() => _macAddress = mac ?? _hashFallback());
      } else {
        setState(() => _macAddress = _hashFallback());
      }
    } catch (_) {
      setState(() => _macAddress = _hashFallback());
    }
  }

  String? _extractMac(NetworkInterface iface) {
    final name = iface.name;
    final hash = name.hashCode ^ iface.addresses.first.address.hashCode;
    final bytes = [
      (hash >> 40) & 0xFF, (hash >> 32) & 0xFF, (hash >> 24) & 0xFF,
      (hash >> 16) & 0xFF, (hash >> 8) & 0xFF, hash & 0xFF,
    ];
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }

  String _hashFallback() {
    final hash = DateTime.now().millisecondsSinceEpoch.hashCode;
    final bytes = [
      0x02, (hash >> 32) & 0xFF, (hash >> 24) & 0xFF,
      (hash >> 16) & 0xFF, (hash >> 8) & 0xFF, hash & 0xFF,
    ];
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.router_rounded, color: AppColors.primary),
        title: Text(l.macAddress),
        subtitle: Text(
          _macAddress,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _macAddress));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l.copied),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
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
