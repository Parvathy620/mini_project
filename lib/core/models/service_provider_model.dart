class ServiceProviderModel {
  final String uid;
  final String name;
  final String email;
  final String destinationId;
  final List<String> categoryIds; // Changed from categoryId
  final bool isApproved;
  final DateTime? createdAt;
  final double rating;
  final String priceRange;
  final double price; // New numeric price field

  final List<String> services;
  final String profileImageUrl;
  final bool isAvailable;
  final String description;
  final String experience;
  final String location;
  final String googleDriveImageId;
  final String googleDriveImageUrl;
  final bool isHidden;
  final bool isDeleted;

  ServiceProviderModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.destinationId,
    required this.categoryIds,
    this.isApproved = false,
    this.createdAt,
    this.rating = 0.0,
    this.priceRange = '',
    this.price = 0.0,
    this.services = const [],
    this.profileImageUrl = '', 
    this.isAvailable = true,
    this.description = '',
    this.experience = '',
    this.location = '',
    this.googleDriveImageId = '',
    this.googleDriveImageUrl = '',
    this.isHidden = false,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'destinationId': destinationId,
      'categoryIds': categoryIds,
      'isApproved': isApproved,
      'createdAt': createdAt,
      'role': 'service_provider',
      'rating': rating,
      'priceRange': priceRange,
      'price': price,
      'services': services,
      'profileImageUrl': profileImageUrl,
      'isAvailable': isAvailable,
      'description': description,
      'experience': experience,
      'location': location,
      'googleDriveImageId': googleDriveImageId,
      'googleDriveImageUrl': googleDriveImageUrl,
      'isHidden': isHidden,
      'isDeleted': isDeleted,
    };
  }

  factory ServiceProviderModel.fromMap(Map<String, dynamic> data, String uid) {
    // Handle migration from single categoryId to list if needed
    List<String> validCategoryIds = [];
    if (data['categoryIds'] != null) {
      validCategoryIds = List<String>.from(data['categoryIds']);
    } else if (data['categoryId'] != null) {
      validCategoryIds = [data['categoryId']];
    }

    return ServiceProviderModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      destinationId: data['destinationId'] ?? '',
      categoryIds: validCategoryIds,
      isApproved: data['isApproved'] ?? false,
      createdAt: data['createdAt'] != null ? (data['createdAt']).toDate() : null,
      rating: (data['rating'] ?? 0.0).toDouble(),
      priceRange: data['priceRange'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      services: List<String>.from(data['services'] ?? []),
      profileImageUrl: data['profileImageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      description: data['description'] ?? '',
      experience: data['experience'] ?? '',
      location: data['location'] ?? '',
      googleDriveImageId: data['googleDriveImageId'] ?? '',
      googleDriveImageUrl: data['googleDriveImageUrl'] ?? '',
      isHidden: data['isHidden'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
    );
  }
}
