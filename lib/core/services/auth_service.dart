import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    required String categoryId,
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
        categoryId: categoryId,
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
  }

  // Password Reset
  //Future<void> sendPasswordResetEmail(String email) async {
    //await _auth.sendPasswordResetEmail(email: email);
  //}

  // Password Reset
Future<void> sendPasswordResetEmail(String email) async {
  try {
    await _auth.sendPasswordResetEmail(email: email);
  } on FirebaseAuthException catch (e) {
    if (kDebugMode) {
      print('Password reset error: ${e.code}');
    }

    // Convert Firebase errors to readable messages
    switch (e.code) {
      case 'user-not-found':
        throw Exception('No user found with this email.');
      case 'invalid-email':
        throw Exception('Invalid email address.');
      default:
        throw Exception('Failed to send password reset email.');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
    throw Exception('Something went wrong. Try again.');
  }
}
}

