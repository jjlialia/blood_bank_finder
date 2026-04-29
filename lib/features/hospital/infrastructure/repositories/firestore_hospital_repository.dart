import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/hospital.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/repositories/hospital_repository.dart';
import '../mappers/hospital_mapper.dart';

class FirestoreHospitalRepository implements IHospitalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<HospitalEntity>> streamHospitals({
    String? islandGroup,
    String? region,
    String? city,
    String? barangay,
  }) {
    Query query = _firestore.collection('hospitals').where('isActive', isEqualTo: true);

    if (islandGroup != null) query = query.where('islandGroup', isEqualTo: islandGroup);
    if (region != null) query = query.where('region', isEqualTo: region);
    if (city != null) query = query.where('city', isEqualTo: city);
    if (barangay != null) query = query.where('barangay', isEqualTo: barangay);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => HospitalMapper.fromFirestore(doc))
        .toList());
  }

  @override
  Future<HospitalEntity?> getHospitalById(String id) async {
    final doc = await _firestore.collection('hospitals').doc(id).get();
    return doc.exists ? HospitalMapper.fromFirestore(doc) : null;
  }

  @override
  Stream<List<InventoryEntity>> streamInventory(String hospitalId) {
    return _firestore
        .collection('hospitals')
        .doc(hospitalId)
        .collection('inventory')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HospitalMapper.fromInventoryFirestore(doc))
            .toList());
  }

  @override
  Future<void> updateInventory(String hospitalId, InventoryEntity inventory) async {
    final data = HospitalMapper.toInventoryFirestore(inventory);
    
    // We use bloodType as the document ID for inventory to ensure uniqueness
    await _firestore
        .collection('hospitals')
        .doc(hospitalId)
        .collection('inventory')
        .doc(inventory.bloodType)
        .set(data);
  }

  @override
  Future<void> createHospital(HospitalEntity hospital) async {
    final data = HospitalMapper.toFirestore(hospital);
    await _firestore.collection('hospitals').add(data);
  }

  @override
  Future<void> updateHospital(HospitalEntity hospital) async {
    final data = HospitalMapper.toFirestore(hospital);
    await _firestore.collection('hospitals').doc(hospital.id).update(data);
  }
}
