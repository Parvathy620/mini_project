import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewStatus { approved, pending, rejected }

class ReviewModel {
  final String id;
  final String targetId; // ID of the Destination or Service Provider
  final String targetType; // 'destination' or 'service_provider'
  final String userId;
  final String userName;
  final String userProfilePic;
  final double rating;
  final String title;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int helpfulVotes;
  final ReviewStatus status;

  // Added for Service Provider Dashboard
  final String? bookingId;
  final String? providerReply;
  final String? serviceType;

  ReviewModel({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.userId,
    required this.userName,
    this.userProfilePic = '',
    required this.rating,
    this.title = '',
    required this.text,
    required this.createdAt,
    this.updatedAt,
    this.helpfulVotes = 0,
    this.status = ReviewStatus.pending,
    this.bookingId,
    this.providerReply,
    this.serviceType,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous User',
      userProfilePic: data['userProfilePic'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      title: data['title'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      helpfulVotes: data['helpfulVotes'] ?? 0,
      status: ReviewStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => ReviewStatus.pending,
      ),
      bookingId: data['bookingId'],
      providerReply: data['providerReply'],
      serviceType: data['serviceType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetId': targetId,
      'targetType': targetType,
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'rating': rating,
      'title': title,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'helpfulVotes': helpfulVotes,
      'status': status.toString().split('.').last,
      'bookingId': bookingId,
      'providerReply': providerReply,
      'serviceType': serviceType,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? targetId,
    String? targetType,
    String? userId,
    String? userName,
    String? userProfilePic,
    double? rating,
    String? title,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? helpfulVotes,
    ReviewStatus? status,
    String? bookingId,
    String? providerReply,
    String? serviceType,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      status: status ?? this.status,
      bookingId: bookingId ?? this.bookingId,
      providerReply: providerReply ?? this.providerReply,
      serviceType: serviceType ?? this.serviceType,
    );
  }
}
