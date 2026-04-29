import '../../domain/entities/hospital.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/repositories/hospital_repository.dart';

class StreamHospitalsUseCase {
  final IHospitalRepository repository;

  StreamHospitalsUseCase(this.repository);

  Stream<List<HospitalEntity>> execute({
    String? islandGroup,
    String? region,
    String? city,
    String? barangay,
  }) {
    return repository.streamHospitals(
      islandGroup: islandGroup,
      region: region,
      city: city,
      barangay: barangay,
    );
  }
}

class GetHospitalUseCase {
  final IHospitalRepository repository;

  GetHospitalUseCase(this.repository);

  Future<HospitalEntity?> execute(String id) async {
    return await repository.getHospitalById(id);
  }
}

class StreamInventoryUseCase {
  final IHospitalRepository repository;

  StreamInventoryUseCase(this.repository);

  Stream<List<InventoryEntity>> execute(String hospitalId) {
    return repository.streamInventory(hospitalId);
  }
}

class UpdateInventoryUseCase {
  final IHospitalRepository repository;

  UpdateInventoryUseCase(this.repository);

  Future<void> execute(String hospitalId, InventoryEntity inventory) async {
    await repository.updateInventory(hospitalId, inventory);
  }
}
class UpdateHospitalUseCase {
  final IHospitalRepository repository;

  UpdateHospitalUseCase(this.repository);

  Future<void> execute(HospitalEntity hospital) async {
    await repository.updateHospital(hospital);
  }
}
