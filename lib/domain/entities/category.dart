class Category {
  final String id;
  final String name;
  final int channelCount;

  const Category({
    required this.id,
    required this.name,
    this.channelCount = 0,
  });

  Category copyWith({String? id, String? name, int? channelCount}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      channelCount: channelCount ?? this.channelCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Category && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
