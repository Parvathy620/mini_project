class DestinationModel {
  final String id;
  final String name;
  final String description;

  DestinationModel({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory DestinationModel.fromMap(Map<String, dynamic> data, String id) {
    return DestinationModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }
}
