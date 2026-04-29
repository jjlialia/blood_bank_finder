import '../entities/blood_request.dart';

abstract class IBloodRequestRepository {
  Stream<List<BloodRequestEntity>> getAllRequests();
  Stream<List<BloodRequestEntity>> getUserRequests(String userId);
  Stream<List<BloodRequestEntity>> getHospitalRequests(String hospitalId);
  Future<BloodRequestEntity?> getRequestById(String id);
  Future<void> createRequest(BloodRequestEntity request);
  Future<void> updateRequestStatus(String id, String status, {String? adminMessage});
}
