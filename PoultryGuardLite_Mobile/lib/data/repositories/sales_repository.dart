import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/logger_service.dart';
import '../../features/flock/models/sales_model.dart';
import 'base_repository.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class SalesRepository extends BaseFirestoreRepository<SalesModel> {
  SalesRepository(super.firestore, super.auth);

  CollectionReference<Map<String, dynamic>> _sales(
          String farmId, String batchId) =>
      firestore
          .collection('farms')
          .doc(farmId)
          .collection('batches')
          .doc(batchId)
          .collection('sales');

  @override
  SalesModel fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return SalesModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<SalesModel>> watchSales(String farmId, String batchId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    
    return safeCollectionStream(
      _sales(farmId, batchId).snapshots(),
      'SalesRepository.watchSales',
    ).map((sales) {
      return sales..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> addOrUpdateSale(
      String farmId, String batchId, SalesModel sale) async {
    try {
      final user = requireCurrentUser();
      final docRef = sale.id.isEmpty
          ? _sales(farmId, batchId).doc()
          : _sales(farmId, batchId).doc(sale.id);
      
      final Map<String, dynamic> saleMap = sale.toMap();
      saleMap['ownerId'] = user.uid; // Ensure ownerId is set for security rules

      final data = sale.id.isEmpty
          ? withTimestamps(saleMap, isCreate: true)
          : withTimestamps(saleMap, isCreate: false);
          
      await docRef.set(data, SetOptions(merge: true));
      AppLogger.i('[SalesRepository] addOrUpdateSale → saved.');
    } on UnauthenticatedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('[SalesRepository] addOrUpdateSale failed', error: e, stackTrace: st);
      throw RepositoryException('Failed to save sale.', cause: e);
    }
  }

  Future<void> deleteSale(String farmId, String batchId, String saleId) async {
    try {
      requireCurrentUser();
      await _sales(farmId, batchId).doc(saleId).delete();
      AppLogger.i('[SalesRepository] deleteSale → deleted.');
    } on UnauthenticatedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('[SalesRepository] deleteSale failed', error: e, stackTrace: st);
      throw RepositoryException('Failed to delete sale.', cause: e);
    }
  }
}
