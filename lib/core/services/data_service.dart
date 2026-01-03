import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destination_model.dart';
import '../models/category_model.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DestinationModel>> getDestinations() {
    return _firestore.collection('destinations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DestinationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<CategoryModel>> getCategories() {
    return _firestore.collection('service_provider_categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
