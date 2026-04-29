import '../../../auth/domain/entities/user.dart';
import '../../../hospital/domain/entities/hospital.dart';
import '../entities/audit_log.dart';

abstract class ISuperAdminRepository {
  Stream<List<UserEntity>> streamAllUsers();
  Future<void> updateUserStatus(String userId, bool isBanned);
  Future<void> updateUserRole(String userId, String role, {String? hospitalId});
  
  Stream<List<HospitalEntity>> streamAllHospitals();
  Future<void> createHospital(HospitalEntity hospital);
  Future<void> updateHospital(HospitalEntity hospital);
  Future<UserEntity?> getUser(String userId);
  Future<void> updateUser(UserEntity user);
  
  Stream<List<AuditLogEntity>> streamAuditLogs({String? category});
  Future<void> logAction(AuditLogEntity log);
}
