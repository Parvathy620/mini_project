class AdminModel {
  final String uid;
  final String email;
  final String? name;
  final String role;
  final DateTime? createdAt;

  AdminModel({
    required this.uid,
    required this.email,
    this.name,
    this.role = 'admin',
    this.createdAt,
  });

  factory AdminModel.fromMap(Map<String, dynamic> data, String uid) {
    return AdminModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'],
      role: data['role'] ?? 'admin',
      createdAt: data['createdAt'] != null
          ? (data['createdAt']).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
