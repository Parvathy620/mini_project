import 'package:cloud_firestore/cloud_firestore.dart';

enum IssuePriority { low, medium, high, urgent }

enum IssueStatus { pending, inProgress, resolved, rejected }

class IssueModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final IssuePriority priority;
  final IssueStatus status;
  final String reporterId;
  final String? reporterName; // Denormalized for easy listing
  final IssueLocation? location;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminNote;

  IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.priority = IssuePriority.medium,
    this.status = IssueStatus.pending,
    required this.reporterId,
    this.reporterName,
    this.location,
    this.mediaUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.adminNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.name,
      'status': status.name,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'location': location?.toMap(),
      'mediaUrls': mediaUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'adminNote': adminNote,
    };
  }

  factory IssueModel.fromMap(Map<String, dynamic> map, String id) {
    return IssueModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      priority: IssuePriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => IssuePriority.medium,
      ),
      status: IssueStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => IssueStatus.pending,
      ),
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'],
      location: map['location'] != null ? IssueLocation.fromMap(map['location']) : null,
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      adminNote: map['adminNote'],
    );
  }
}

class IssueLocation {
  final double? latitude;
  final double? longitude;
  final String? address;

  IssueLocation({
    this.latitude,
    this.longitude,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory IssueLocation.fromMap(Map<String, dynamic> map) {
    return IssueLocation(
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      address: map['address'],
    );
  }
}
