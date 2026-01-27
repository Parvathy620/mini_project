class DestinationModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  final String district;
  final String category;
  final double rating;
  final bool isAvailable;

  DestinationModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.district = '',
    this.category = 'Tourist Place',
    this.rating = 4.5,
    this.isAvailable = true,
  });

  factory DestinationModel.fromMap(Map<String, dynamic> data, String id) {
    return DestinationModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      district: data['district'] ?? '',
      category: data['category'] ?? 'Tourist Place',
      rating: (data['rating'] ?? 4.5).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'district': district,
      'category': category,
      'rating': rating,
      'isAvailable': isAvailable,
    };
  }
}
