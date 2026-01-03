import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destination_model.dart';
import '../models/category_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Destinations ---

  Stream<List<DestinationModel>> getDestinations() {
    return _firestore.collection('destinations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DestinationModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addDestination(String name, String description) async {
    await _firestore.collection('destinations').add({
      'name': name,
      'description': description,
    });
  }

  Future<void> updateDestination(String id, String name, String description) async {
    await _firestore.collection('destinations').doc(id).update({
      'name': name,
      'description': description,
    });
  }

  Future<void> deleteDestination(String id) async {
    await _firestore.collection('destinations').doc(id).delete();
  }

  // --- Categories ---

  Stream<List<CategoryModel>> getCategories() {
    return _firestore.collection('service_provider_categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addCategory(String name, String description) async {
    await _firestore.collection('service_provider_categories').add({
      'categoryName': name,
      'description': description,
    });
  }

  Future<void> updateCategory(String id, String name, String description) async {
    await _firestore.collection('service_provider_categories').doc(id).update({
      'categoryName': name,
      'description': description,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection('service_provider_categories').doc(id).delete();
  }
}
