import '../../domain/entities/category.dart';

class CategoryModel {
  final String id;
  final String name;
  final int channelCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.channelCount = 0,
  });

  Category toEntity() {
    return Category(id: id, name: name, channelCount: channelCount);
  }

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      channelCount: category.channelCount,
    );
  }

  factory CategoryModel.fromXtreamJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['category_id']?.toString() ?? '',
      name: json['category_name']?.toString() ?? 'Unknown',
    );
  }
}
