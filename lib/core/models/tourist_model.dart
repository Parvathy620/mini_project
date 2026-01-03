class TouristModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? createdAt;

  TouristModel({
    required this.uid,
    required this.name,
    required this.email,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'role': 'tourist',
    };
  }

  factory TouristModel.fromMap(Map<String, dynamic> data, String uid) {
    return TouristModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt']).toDate() : null,
    );
  }
}
