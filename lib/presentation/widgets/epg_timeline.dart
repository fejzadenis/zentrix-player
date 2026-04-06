import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/epg_program.dart';

class EpgTimeline extends StatelessWidget {
  final List<EpgProgram> programs;

  const EpgTimeline({super.key, required this.programs});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (programs.isEmpty) {
      return Center(child: Text(l.noProgramData));
    }

    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        final isNow =
            now.isAfter(program.startTime) && now.isBefore(program.endTime);
        final isPast = now.isAfter(program.endTime);

        return _ProgramCard(
          program: program,
          isNow: isNow,
          isPast: isPast,
          timeFormat: timeFormat,
        );
      },
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final EpgProgram program;
  final bool isNow;
  final bool isPast;
  final DateFormat timeFormat;

  const _ProgramCard({
    required this.program,
    required this.isNow,
    required this.isPast,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isNow
              ? AppColors.primary.withValues(alpha: 0.12)
              : isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: isNow
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isNow)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.live,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l.now,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Text(
                    '${timeFormat.format(program.startTime)} - ${timeFormat.format(program.endTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isPast ? AppColors.textSecondary : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                program.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isPast
                      ? AppColors.textSecondary
                      : null,
                ),
              ),
              if (program.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  program.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (isNow) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: program.progress,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
