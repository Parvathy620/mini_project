class DestinationModel {
  final String id;
  final String name;
  final String description;
  final String district;

  DestinationModel({
    required this.id,
    required this.name,
    this.description = '',
    this.district = '',
  });

  factory DestinationModel.fromMap(Map<String, dynamic> data, String id) {
    return DestinationModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      district: data['district'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'district': district,
    };
  }
}
