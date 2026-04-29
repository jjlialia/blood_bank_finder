import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/infrastructure/mappers/user_mapper.dart';
import '../../../hospital/domain/entities/hospital.dart';
import '../../../hospital/infrastructure/mappers/hospital_mapper.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/super_admin_repository.dart';

class FirestoreSuperAdminRepository implements ISuperAdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<UserEntity>> streamAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserMapper.fromFirestore(doc)).toList());
  }

  @override
  Future<void> updateUserStatus(String userId, bool isBanned) async {
    await _firestore.collection('users').doc(userId).update({'isBanned': isBanned});
  }

  @override
  Future<void> updateUserRole(String userId, String role, {String? hospitalId}) async {
    await _firestore.collection('users').doc(userId).update({
      'role': role,
      'hospitalId': hospitalId,
    });
  }

  @override
  Stream<List<HospitalEntity>> streamAllHospitals() {
    return _firestore.collection('hospitals').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => HospitalMapper.fromFirestore(doc)).toList());
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

  @override
  Future<UserEntity?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserMapper.fromFirestore(doc);
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    final data = UserMapper.toFirestore(user);
    await _firestore.collection('users').doc(user.uid).update(data);
  }

  @override
  Stream<List<AuditLogEntity>> streamAuditLogs({String? category}) {
    Query query = _firestore.collection('audit_logs').orderBy('timestamp', descending: true);
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AuditLogEntity.fromFirestore(doc)).toList());
  }

  @override
  Future<void> logAction(AuditLogEntity log) async {
    final data = log.toFirestore();
    await _firestore.collection('audit_logs').add(data);
  }
}
