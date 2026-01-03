class ServiceProviderModel {
  final String uid;
  final String name;
  final String email;
  final String destinationId;
  final String categoryId;
  final bool isApproved;
  final DateTime? createdAt;

  ServiceProviderModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.destinationId,
    required this.categoryId,
    this.isApproved = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'destinationId': destinationId,
      'categoryId': categoryId,
      'isApproved': isApproved,
      'createdAt': createdAt,
      'role': 'service_provider', // consistent role field
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
    );
  }
}
