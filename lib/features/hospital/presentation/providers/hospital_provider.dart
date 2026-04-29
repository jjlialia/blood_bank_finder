import 'package:flutter/material.dart';
import '../../domain/entities/hospital.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/repositories/hospital_repository.dart';
import '../../infrastructure/repositories/firestore_hospital_repository.dart';
import '../../application/use_cases/hospital_use_cases.dart';

class HospitalProvider with ChangeNotifier {
  late final IHospitalRepository _repository;
  late final StreamHospitalsUseCase _streamHospitalsUseCase;
  late final GetHospitalUseCase _getHospitalUseCase;
  late final StreamInventoryUseCase _streamInventoryUseCase;
  late final UpdateInventoryUseCase _updateInventoryUseCase;
  late final UpdateHospitalUseCase _updateHospitalUseCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  HospitalProvider() {
    _repository = FirestoreHospitalRepository();
    _streamHospitalsUseCase = StreamHospitalsUseCase(_repository);
    _getHospitalUseCase = GetHospitalUseCase(_repository);
    _streamInventoryUseCase = StreamInventoryUseCase(_repository);
    _updateInventoryUseCase = UpdateInventoryUseCase(_repository);
    _updateHospitalUseCase = UpdateHospitalUseCase(_repository);
  }

  // Streams
  Stream<List<HospitalEntity>> streamHospitals({
    String? islandGroup,
    String? region,
    String? city,
    String? barangay,
  }) {
    return _streamHospitalsUseCase.execute(
      islandGroup: islandGroup,
      region: region,
      city: city,
      barangay: barangay,
    );
  }

  Stream<List<InventoryEntity>> streamInventory(String hospitalId) {
    return _streamInventoryUseCase.execute(hospitalId);
  }

  // Actions
  Future<HospitalEntity?> getHospital(String id) async {
    return await _getHospitalUseCase.execute(id);
  }

  Future<String?> updateInventory(String hospitalId, InventoryEntity inventory) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _updateInventoryUseCase.execute(hospitalId, inventory);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> updateHospital(HospitalEntity hospital) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _updateHospitalUseCase.execute(hospital);
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
