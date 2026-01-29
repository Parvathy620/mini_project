import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_provider_model.dart';
import '../models/tourist_model.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code}');
      }
      rethrow; // Pass error to UI
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      rethrow;
    }
  }

  // Sign up Service Provider
  Future<void> signUpServiceProvider({
    required String email,
    required String password,
    required String name,
    required String destinationId,
    required List<String> categoryIds,
  }) async {
    try {
      // 1. Create Auth User
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Create Service Provider Model
      ServiceProviderModel sp = ServiceProviderModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        destinationId: destinationId,
        categoryIds: categoryIds,
        isApproved: false, // Default to false
        createdAt: DateTime.now(),
      );

      // 3. Store in Firestore
      await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(credential.user!.uid)
          .set(sp.toMap());
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      rethrow;
    }
  }

  // Sign up Tourist
  Future<void> signUpTourist({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Create Auth User
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Create Tourist Model
      TouristModel tourist = TouristModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      // 3. Store in Firestore
      await FirebaseFirestore.instance
          .collection('tourists')
          .doc(credential.user!.uid)
          .set(tourist.toMap());
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_route');
    // Note: We deliberately KEEP 'last_email' and 'last_role_index' for "Remember Me"
  }

  // Password Reset
  //Future<void> sendPasswordResetEmail(String email) async {
    //await _auth.sendPasswordResetEmail(email: email);
  //}

  // Password Reset


  // Confirm Password Reset (In-App)
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'expired-action-code') {
        throw Exception('The password reset link has expired.');
      }
      if (e.code == 'invalid-action-code') {
         throw Exception('The link is invalid or has already been used.');
      }
      if (e.code == 'weak-password') {
         throw Exception('Password is too weak.');
      }
      throw Exception('Failed to reset password: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  // Password Reset with Deep Link
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Configuration for Deep Linking
      // NOTE: strict match of packageName is important
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: 'https://project1-b26ed.firebaseapp.com/__/auth/action?mode=resetPassword', // Must match one in Authorized Redirect URIs in Console
        handleCodeInApp: true,
        iOSBundleId: 'com.tourism.tourism_app', // Updated to match Android package likely
        androidPackageName: 'com.tourism.tourism_app', // Corrected from build.gradle.kts
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );

      await _auth.sendPasswordResetEmail(
        email: email, 
        actionCodeSettings: actionCodeSettings
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Password reset error: ${e.code}');
      }
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        case 'missing-android-pkg-name':
          throw Exception('Android package name is missing.');
        default:
          throw Exception('Failed to send password reset email: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      throw Exception('Something went wrong. Try again.');
    }
  }
  
  // IN-APP Change Password (Logged In)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in.');
    
    // 1. Re-authenticate to ensure security
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!, // Email is assumed to be available
        password: currentPassword
      );
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect current password.');
      } else {
        throw Exception('Re-authentication failed: ${e.message}');
      }
    }

    // 2. Update Password
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
         throw Exception('Password is too weak. Use at least 6 characters.');
      }
      throw Exception('Failed to update password: ${e.message}');
    }
  }
  // Update Tourist Profile
  Future<void> updateTouristProfile({
    required String uid,
    required String name,
    required String? age,
    required String? mobile,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('tourists').doc(uid).update({
        'name': name,
        'age': age,
        'mobile': mobile,
      });
      
      // Also update Auth Display Name
      await _auth.currentUser?.updateDisplayName(name);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      throw Exception('Failed to update profile');
    }
  }
  // Get User Role
  Future<String?> getUserRole(String uid) async {
    try {
      // 1. Check Admin
      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      if (adminDoc.exists && (adminDoc.data() as Map<String, dynamic>)['role'] == 'admin') {
        return 'admin';
      }

      // 2. Check Service Provider
      final spDoc = await FirebaseFirestore.instance.collection('service_providers').doc(uid).get();
      if (spDoc.exists) {
        return 'provider';
      }

      // 3. Check Tourist
      final touristDoc = await FirebaseFirestore.instance.collection('tourists').doc(uid).get();
      if (touristDoc.exists) {
        return 'tourist';
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) print('Error fetching user role: $e');
      return null;
    }
  }

  // Toggle Wishlist
  Future<void> toggleWishlist(String uid, String destinationId) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('tourists').doc(uid);
      final doc = await docRef.get();
      if (doc.exists) {
        List<String> wishlist = List<String>.from(doc.data()?['wishlist'] ?? []);
        if (wishlist.contains(destinationId)) {
          wishlist.remove(destinationId);
        } else {
          wishlist.add(destinationId);
        }
        await docRef.update({'wishlist': wishlist});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling wishlist: $e');
      }
      throw Exception('Failed to update wishlist');
    }
  }
}

