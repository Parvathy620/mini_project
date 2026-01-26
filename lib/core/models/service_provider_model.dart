class ServiceProviderModel {
  final String uid;
  final String name;
  final String email;
  final String destinationId;
  final String categoryId;
  final bool isApproved;
  final DateTime? createdAt;
  final double rating;
  final String priceRange;
  final List<String> services;
  final String profileImageUrl;
  final bool isAvailable;

  ServiceProviderModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.destinationId,
    required this.categoryId,
    this.isApproved = false,
    this.createdAt,
    this.rating = 0.0,
    this.priceRange = '',
    this.services = const [],
    this.profileImageUrl = '',
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'destinationId': destinationId,
      'categoryId': categoryId,
      'isApproved': isApproved,
      'createdAt': createdAt,
      'role': 'service_provider',
      'rating': rating,
      'priceRange': priceRange,
      'services': services,
      'profileImageUrl': profileImageUrl,
      'isAvailable': isAvailable,
    };
  }

  factory ServiceProviderModel.fromMap(Map<String, dynamic> data, String uid) {
    return ServiceProviderModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      destinationId: data['destinationId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      isApproved: data['isApproved'] ?? false,
      createdAt: data['createdAt'] != null ? (data['createdAt']).toDate() : null,
      rating: (data['rating'] ?? 0.0).toDouble(),
      priceRange: data['priceRange'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      profileImageUrl: data['profileImageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }
}
