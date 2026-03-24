class DestinationModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String googleDriveImageUrl;
  final String district;
  final String category;
  final double rating;
  final bool isAvailable;
  final double latitude;
  final double longitude;
  final String openingTime;
  final String closingTime;

  DestinationModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.googleDriveImageUrl = '',
    this.district = '',
    this.category = 'Tourist Place',
    this.rating = 4.5,
    this.isAvailable = true,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.openingTime = 'Not Specified',
    this.closingTime = 'Not Specified',
  });

  factory DestinationModel.fromMap(Map<String, dynamic> data, String id) {
    return DestinationModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      googleDriveImageUrl: data['googleDriveImageUrl'] ?? '',
      district: data['district'] ?? '',
      category: data['category'] ?? 'Tourist Place',
      rating: (data['rating'] ?? 4.5).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      openingTime: data['openingTime'] ?? 'Not Specified',
      closingTime: data['closingTime'] ?? 'Not Specified',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'googleDriveImageUrl': googleDriveImageUrl,
      'district': district,
      'category': category,
      'rating': rating,
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'openingTime': openingTime,
      'closingTime': closingTime,
    };
  }
}
