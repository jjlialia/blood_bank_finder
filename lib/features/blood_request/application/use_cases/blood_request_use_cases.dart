import '../../domain/entities/blood_request.dart';
import '../../domain/repositories/blood_request_repository.dart';

class GetBloodRequestsUseCase {
  final IBloodRequestRepository repository;

  GetBloodRequestsUseCase(this.repository);

  Stream<List<BloodRequestEntity>> execute({String? userId, String? hospitalId}) {
    if (userId != null) {
      return repository.getUserRequests(userId);
    } else if (hospitalId != null) {
      return repository.getHospitalRequests(hospitalId);
    } else {
      return repository.getAllRequests();
    }
  }
}

class SubmitBloodRequestUseCase {
  final IBloodRequestRepository repository;

  SubmitBloodRequestUseCase(this.repository);

  Future<void> execute(BloodRequestEntity request) async {
    // Add business rules here (e.g., check for existing pending requests)
    await repository.createRequest(request);
  }
}

class UpdateRequestStatusUseCase {
  final IBloodRequestRepository repository;

  UpdateRequestStatusUseCase(this.repository);

  Future<void> execute(String id, String status, {String? adminMessage}) async {
    await repository.updateRequestStatus(id, status, adminMessage: adminMessage);
  }
}
class GetBloodRequestUseCase {
  final IBloodRequestRepository repository;

  GetBloodRequestUseCase(this.repository);

  Future<BloodRequestEntity?> execute(String id) async {
    return await repository.getRequestById(id);
  }
}
