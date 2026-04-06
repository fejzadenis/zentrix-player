import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/channel_provider.dart';
import '../../providers/epg_provider.dart';
import '../../widgets/epg_timeline.dart';

class EpgScreen extends ConsumerStatefulWidget {
  const EpgScreen({super.key});

  @override
  ConsumerState<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends ConsumerState<EpgScreen> {
  String? _selectedChannelId;

  @override
  Widget build(BuildContext context) {
    final channelState = ref.watch(channelProvider);
    final epgState = ref.watch(epgProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tvGuide),
        actions: [
          if (epgState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: epgState.programsByChannel.isEmpty
          ? _buildEmptyState(context, l)
          : _buildEpgContent(context, channelState, epgState, l),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l.noEpgData,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l.epgAutoLoad,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpgContent(
    BuildContext context,
    ChannelState channelState,
    EpgState epgState,
    AppLocalizations l,
  ) {
    final channelsWithEpg = channelState.channels
        .where((ch) =>
            ch.tvgId.isNotEmpty &&
            epgState.programsByChannel.containsKey(ch.tvgId))
        .toList();

    if (channelsWithEpg.isEmpty) return _buildEmptyState(context, l);

    return Row(
      children: [
        SizedBox(
          width: 180,
          child: ListView.builder(
            itemCount: channelsWithEpg.length,
            itemBuilder: (context, index) {
              final channel = channelsWithEpg[index];
              final isSelected = _selectedChannelId == channel.tvgId;

              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
                leading: channel.logoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          channel.logoUrl,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.tv, size: 18),
                          ),
                        ),
                      )
                    : null,
                title: Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                onTap: () {
                  setState(() => _selectedChannelId = channel.tvgId);
                },
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedChannelId != null &&
                  epgState.programsByChannel.containsKey(_selectedChannelId)
              ? EpgTimeline(
                  programs: epgState.programsByChannel[_selectedChannelId]!,
                )
              : Center(
                  child: Text(
                    l.selectChannelForGuide,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
        ),
      ],
    );
  }
}
