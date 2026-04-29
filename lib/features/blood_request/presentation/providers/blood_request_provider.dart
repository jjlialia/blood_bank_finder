import 'package:flutter/material.dart';
import '../../domain/entities/blood_request.dart';
import '../../domain/repositories/blood_request_repository.dart';
import '../../infrastructure/repositories/firestore_blood_request_repository.dart';
import '../../application/use_cases/blood_request_use_cases.dart';

class BloodRequestProvider with ChangeNotifier {
  late final IBloodRequestRepository _repository;
  late final GetBloodRequestsUseCase _getRequestsUseCase;
  late final GetBloodRequestUseCase _getRequestUseCase;
  late final SubmitBloodRequestUseCase _submitRequestUseCase;
  late final UpdateRequestStatusUseCase _updateStatusUseCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BloodRequestProvider() {
    _repository = FirestoreBloodRequestRepository();
    _getRequestsUseCase = GetBloodRequestsUseCase(_repository);
    _getRequestUseCase = GetBloodRequestUseCase(_repository);
    _submitRequestUseCase = SubmitBloodRequestUseCase(_repository);
    _updateStatusUseCase = UpdateRequestStatusUseCase(_repository);
  }

  // Streams for real-time updates
  Stream<List<BloodRequestEntity>> streamUserRequests(String userId) {
    return _getRequestsUseCase.execute(userId: userId);
  }

  Stream<List<BloodRequestEntity>> streamHospitalRequests(String hospitalId) {
    return _getRequestsUseCase.execute(hospitalId: hospitalId);
  }

  Stream<List<BloodRequestEntity>> streamAllRequests() {
    return _getRequestsUseCase.execute();
  }

  // Actions
  Future<BloodRequestEntity?> getRequest(String id) async {
    return await _getRequestUseCase.execute(id);
  }

  Future<String?> createBloodRequest(BloodRequestEntity request) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _submitRequestUseCase.execute(request);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> updateRequestStatus(String id, String status, {String? adminMessage}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _updateStatusUseCase.execute(id, status, adminMessage: adminMessage);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }
}
