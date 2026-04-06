class Channel {
  final String id;
  final String name;
  final String logoUrl;
  final String streamUrl;
  final String category;
  final String tvgId;
  final bool isLive;
  final bool isFavorite;

  const Channel({
    required this.id,
    required this.name,
    this.logoUrl = '',
    required this.streamUrl,
    this.category = 'Uncategorized',
    this.tvgId = '',
    this.isLive = true,
    this.isFavorite = false,
  });

  Channel copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? streamUrl,
    String? category,
    String? tvgId,
    bool? isLive,
    bool? isFavorite,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      category: category ?? this.category,
      tvgId: tvgId ?? this.tvgId,
      isLive: isLive ?? this.isLive,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Channel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Channel(id: $id, name: $name, category: $category)';
}
