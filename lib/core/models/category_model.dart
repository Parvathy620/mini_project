class CategoryModel {
  final String id;
  final String name;
  final String description;

  CategoryModel({
    required this.id, 
    required this.name,
    this.description = '',
  });

  factory CategoryModel.fromMap(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['categoryName'] ?? '', 
      description: data['description'] ?? '',
    );
  }
}
