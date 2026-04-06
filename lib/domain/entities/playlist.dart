enum PlaylistType { m3uUrl, m3uFile, xtreamCodes }

class Playlist {
  final String id;
  final String name;
  final PlaylistType type;
  final String url;
  final String? username;
  final String? password;
  final String? serverUrl;
  final DateTime addedAt;
  final DateTime? lastUpdated;
  final int channelCount;

  const Playlist({
    required this.id,
    required this.name,
    required this.type,
    this.url = '',
    this.username,
    this.password,
    this.serverUrl,
    required this.addedAt,
    this.lastUpdated,
    this.channelCount = 0,
  });

  Playlist copyWith({
    String? id,
    String? name,
    PlaylistType? type,
    String? url,
    String? username,
    String? password,
    String? serverUrl,
    DateTime? addedAt,
    DateTime? lastUpdated,
    int? channelCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      serverUrl: serverUrl ?? this.serverUrl,
      addedAt: addedAt ?? this.addedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      channelCount: channelCount ?? this.channelCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Playlist && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
