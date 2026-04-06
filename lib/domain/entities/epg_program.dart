class EpgProgram {
  final String channelId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final String iconUrl;

  const EpgProgram({
    required this.channelId,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.category = '',
    this.iconUrl = '',
  });

  bool get isNowPlaying {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 0.0;
    if (now.isAfter(endTime)) return 1.0;
    final total = endTime.difference(startTime).inSeconds;
    final elapsed = now.difference(startTime).inSeconds;
    return total > 0 ? elapsed / total : 0.0;
  }
}
