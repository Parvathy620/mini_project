class TouristModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? createdAt;
  final String? age;
  final String? mobile;
  final List<String> wishlist;

  TouristModel({
    required this.uid,
    required this.name,
    required this.email,
    this.createdAt,
    this.age,
    this.mobile,
    this.wishlist = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'role': 'tourist',
      'age': age,
      'mobile': mobile,
      'wishlist': wishlist,
    };
  }

  factory TouristModel.fromMap(Map<String, dynamic> data, String uid) {
    return TouristModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt']).toDate() : null,
      age: data['age'],
      mobile: data['mobile'],
      wishlist: List<String>.from(data['wishlist'] ?? []),
    );
  }
}
