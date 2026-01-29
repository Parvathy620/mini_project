import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AvailabilityModel {
  final String providerId;
  final List<int> workingDays; // 1 = Monday, 7 = Sunday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int slotDurationMinutes;
  final List<DateTime> blockedDates;
  final Map<String, List<String>> manuallyBlockedSlots; // Key: "yyyy-MM-dd", Value: ["10:00", "14:00"]

  AvailabilityModel({
    required this.providerId,
    this.workingDays = const [1, 2, 3, 4, 5], // Mon-Fri default
    this.startTime = const TimeOfDay(hour: 9, minute: 0),
    this.endTime = const TimeOfDay(hour: 17, minute: 0),
    this.slotDurationMinutes = 60,
    this.blockedDates = const [],
    this.manuallyBlockedSlots = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'workingDays': workingDays,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'slotDurationMinutes': slotDurationMinutes,
      'blockedDates': blockedDates.map((e) => Timestamp.fromDate(e)).toList(),
      // manuallyBlockedSlots logic might need Flattening or a sub-collection for scalability, 
      // but for "Mini Project", a Map is okay if not too huge.
      'manuallyBlockedSlots': manuallyBlockedSlots, 
    };
  }

  factory AvailabilityModel.fromMap(Map<String, dynamic> map) {
    return AvailabilityModel(
      providerId: map['providerId'] ?? '',
      workingDays: List<int>.from(map['workingDays'] ?? [1, 2, 3, 4, 5]),
      startTime: TimeOfDay(
        hour: map['startHour'] ?? 9,
        minute: map['startMinute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endHour'] ?? 17,
        minute: map['endMinute'] ?? 0,
      ),
      slotDurationMinutes: map['slotDurationMinutes'] ?? 60,
      blockedDates: (map['blockedDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      manuallyBlockedSlots: Map<String, List<String>>.from(
          (map['manuallyBlockedSlots'] ?? {}).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          )),
    );
  }
}
