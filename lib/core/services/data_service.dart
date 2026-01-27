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
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    
    // Note: Compound queries with 'isApproved' might require an index.
    query = query.where('isApproved', isEqualTo: true);

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
}
