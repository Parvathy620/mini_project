import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destination_model.dart';
import '../models/category_model.dart';
import '../models/service_provider_model.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DestinationModel>> getDestinations({String? query}) {
    Query collection = _firestore.collection('destinations');
    
    // Note: Firestore doesn't support native partial text search easily without external services like Algolia.
    // We will fetch all and filter client side for this mini-project if query is present,
    // or use startAt/endAt if strict prefix is needed. 
    // For simplicity and "Optimization" in a small app, client-side filtering of the stream is often smoother than constant re-querying Firestore on every keystroke.
    // However, to demonstrate API usage:
    
    return collection.snapshots().map((snapshot) {
      var destinations = snapshot.docs.map((doc) {
        return DestinationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (query != null && query.isNotEmpty) {
        destinations = destinations.where((d) => 
          d.name.toLowerCase().contains(query.toLowerCase()) || 
          d.district.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      return destinations;
    });
  }

  Stream<List<CategoryModel>> getCategories() {
    return _firestore.collection('service_provider_categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<List<ServiceProviderModel>> getServiceProviders({
    String? destinationId,
    String? categoryId,
    String? searchQuery,
  }) {
    Query query = _firestore.collection('service_providers').where('role', isEqualTo: 'service_provider');

    if (destinationId != null && destinationId.isNotEmpty) {
      query = query.where('destinationId', isEqualTo: destinationId);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryIds', arrayContains: categoryId);
    }
    
    // Note: Compound queries with 'isApproved' might require an index.
    query = query.where('isApproved', isEqualTo: true);
    query = query.where('isHidden', isEqualTo: false); // Normal users don't see hidden
    query = query.where('isDeleted', isEqualTo: false); // Normal users don't see deleted

    return query.snapshots().map((snapshot) {
       var providers = snapshot.docs.map((doc) {
        return ServiceProviderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        providers = providers.where((p) => 
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.services.any((s) => s.toLowerCase().contains(searchQuery.toLowerCase()))
        ).toList();
      }
      return providers;
    });
  }

  // ADMIN: Get All Providers (including Hidden/Deleted/Unapproved)
  Stream<List<ServiceProviderModel>> getServiceProvidersForAdmin({String? searchQuery}) {
    Query query = _firestore.collection('service_providers').where('role', isEqualTo: 'service_provider');
    // Note: We do NOT filter by isApproved/isHidden/isDeleted here because Admin sees all.

    return query.snapshots().map((snapshot) {
      var providers = snapshot.docs.map((doc) {
        return ServiceProviderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        providers = providers.where((p) => 
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.email.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }
      
      // Sort: Active first, then Hidden, then Deleted
      providers.sort((a, b) {
        if (a.isDeleted && !b.isDeleted) return 1;
        if (!a.isDeleted && b.isDeleted) return -1;
        if (a.isHidden && !b.isHidden) return 1;
        if (!a.isHidden && b.isHidden) return -1;
        return 0;
      });

      return providers;
    });
  }

  // ADMIN: Toggle Visibility
  Future<void> updateProviderStatus(String uid, {required bool isHidden}) async {
    await _firestore.collection('service_providers').doc(uid).update({
      'isHidden': isHidden,
    });
  }

  // ADMIN: Soft Delete
  Future<void> deleteProvider(String uid) async {
    await _firestore.collection('service_providers').doc(uid).update({
      'isDeleted': true,
      'isHidden': true, // Auto-hide when deleted
    });
  }

  // ADMIN: Restore Provider
  Future<void> restoreProvider(String uid) async {
    await _firestore.collection('service_providers').doc(uid).update({
      'isDeleted': false,
      'isHidden': false, // Auto-show when restored, or leave hidden? 
                         // Logic: Restore implies bringing back to active state usually.
                         // Let's set isHidden to false for immediate visibility.
    });
  }
}
