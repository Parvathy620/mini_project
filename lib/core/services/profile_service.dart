import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/service_provider_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validate Drive URL format
  bool _isValidDriveUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('drive.google.com') && 
           (url.contains('thumbnail') || (url.contains('uc?') && url.contains('id=')));
  }

  // Fetch Profile
  Future<ServiceProviderModel?> getProviderProfile(String uid) async {
    try {
      debugPrint('[ProfileService] INFO: Fetching profile for UID: $uid');
      final doc = await _firestore.collection('service_providers').doc(uid).get();
      
      if (doc.exists) {
        debugPrint('[ProfileService] INFO: Profile found for UID: $uid');
        return ServiceProviderModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      } else {
        debugPrint('[ProfileService] WARNING: No profile found for UID: $uid');
      }
    } catch (e, stackTrace) {
      debugPrint('[ProfileService] ERROR: Failed to fetch profile for $uid - $e');
      debugPrint('[ProfileService] ERROR: Stack trace: $stackTrace');
    }
    return null;
  }

  // Update Profile with validation and retry logic
  Future<void> updateProviderProfile(ServiceProviderModel provider) async {
    try {
      debugPrint('[ProfileService] INFO: Updating profile for UID: ${provider.uid}');
      
      // Validate Drive URL if present
      if (provider.googleDriveImageUrl.isNotEmpty) {
        if (!_isValidDriveUrl(provider.googleDriveImageUrl)) {
          debugPrint('[ProfileService] ERROR: Invalid Drive URL: ${provider.googleDriveImageUrl}');
          throw Exception('Invalid Google Drive URL format');
        }
        debugPrint('[ProfileService] INFO: Drive URL validated: ${provider.googleDriveImageUrl}');
      }
      
      // Convert to map
      final data = provider.toMap();
      debugPrint('[ProfileService] INFO: Profile data prepared for update');
      
      // Update Firestore with timeout
      await _firestore
          .collection('service_providers')
          .doc(provider.uid)
          .update(data)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[ProfileService] ERROR: Firestore update timeout');
              throw Exception('Profile update timeout - please check your connection');
            },
          );
      
      debugPrint('[ProfileService] SUCCESS: Profile updated successfully for UID: ${provider.uid}');
    } catch (e, stackTrace) {
      debugPrint('[ProfileService] ERROR: Failed to update profile for ${provider.uid} - $e');
      debugPrint('[ProfileService] ERROR: Stack trace: $stackTrace');
      rethrow;
    }
  }
}
