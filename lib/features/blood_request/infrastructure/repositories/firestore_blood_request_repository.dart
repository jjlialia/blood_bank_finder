import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/blood_request.dart';
import '../../domain/repositories/blood_request_repository.dart';
import '../mappers/blood_request_mapper.dart';

class FirestoreBloodRequestRepository implements IBloodRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<BloodRequestEntity>> getAllRequests() {
    return _firestore
        .collection('blood_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestMapper.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<BloodRequestEntity>> getUserRequests(String userId) {
    return _firestore
        .collection('blood_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestMapper.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<BloodRequestEntity>> getHospitalRequests(String hospitalId) {
    return _firestore
        .collection('blood_requests')
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestMapper.fromFirestore(doc))
            .toList());
  }

  @override
  Future<BloodRequestEntity?> getRequestById(String id) async {
    final doc = await _firestore.collection('blood_requests').doc(id).get();
    return doc.exists ? BloodRequestMapper.fromFirestore(doc) : null;
  }

  @override
  Future<void> createRequest(BloodRequestEntity request) async {
    final data = BloodRequestMapper.toFirestore(request);
    await _firestore.collection('blood_requests').add(data);
  }

  @override
  Future<void> updateRequestStatus(String id, String status, {String? adminMessage}) async {
    await _firestore.collection('blood_requests').doc(id).update({
      'status': status,
      if (adminMessage != null) 'adminMessage': adminMessage,
    });
  }
}
