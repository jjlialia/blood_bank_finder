import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../hospital/domain/entities/hospital.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/super_admin_repository.dart';

class SuperAdminProvider extends ChangeNotifier {
  final ISuperAdminRepository _repository;

  SuperAdminProvider(this._repository);

  Stream<List<UserEntity>> streamAllUsers() => _repository.streamAllUsers();
  
  Future<void> updateUserStatus(String userId, bool isBanned) async {
    await _repository.updateUserStatus(userId, isBanned);
    notifyListeners();
  }

  Future<void> updateUserRole(String userId, String role, {String? hospitalId}) async {
    await _repository.updateUserRole(userId, role, hospitalId: hospitalId);
    notifyListeners();
  }

  Stream<List<HospitalEntity>> streamAllHospitals() => _repository.streamAllHospitals();

  Future<void> createHospital(HospitalEntity hospital) async {
    await _repository.createHospital(hospital);
    notifyListeners();
  }

  Future<void> updateHospital(HospitalEntity hospital) async {
    await _repository.updateHospital(hospital);
    notifyListeners();
  }

  Future<UserEntity?> getUser(String userId) async {
    return await _repository.getUser(userId);
  }

  Future<void> updateUser(UserEntity user) async {
    await _repository.updateUser(user);
    notifyListeners();
  }

  Stream<List<AuditLogEntity>> streamAuditLogs({String? category}) => 
      _repository.streamAuditLogs(category: category);

  Future<void> logAction(AuditLogEntity log) async {
    await _repository.logAction(log);
    notifyListeners();
  }
}
