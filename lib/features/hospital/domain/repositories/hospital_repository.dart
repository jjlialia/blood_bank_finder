import '../entities/hospital.dart';
import '../entities/inventory.dart';

abstract class IHospitalRepository {
  Stream<List<HospitalEntity>> streamHospitals({
    String? islandGroup,
    String? region,
    String? city,
    String? barangay,
  });
  
  Future<HospitalEntity?> getHospitalById(String id);
  
  Stream<List<InventoryEntity>> streamInventory(String hospitalId);
  Future<void> updateInventory(String hospitalId, InventoryEntity inventory);
  
  Future<void> createHospital(HospitalEntity hospital);
  Future<void> updateHospital(HospitalEntity hospital);
}
