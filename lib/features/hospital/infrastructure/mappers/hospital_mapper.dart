import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/hospital.dart';
import '../../domain/entities/inventory.dart';
class HospitalMapper {
  static HospitalEntity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HospitalEntity(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      islandGroup: data['islandGroup'] ?? '',
      region: data['region'] ?? '',
      city: data['city'] ?? '',
      barangay: data['barangay'] ?? '',
      address: data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      availableBloodTypes: List<String>.from(data['availableBloodTypes'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toFirestore(HospitalEntity entity) {
    return {
      'name': entity.name,
      'email': entity.email,
      'islandGroup': entity.islandGroup,
      'region': entity.region,
      'city': entity.city,
      'barangay': entity.barangay,
      'address': entity.address,
      'contactNumber': entity.contactNumber,
      'latitude': entity.latitude,
      'longitude': entity.longitude,
      'availableBloodTypes': entity.availableBloodTypes,
      'isActive': entity.isActive,
      'createdAt': Timestamp.fromDate(entity.createdAt),
    };
  }

  static InventoryEntity fromInventoryFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryEntity(
      id: doc.id,
      bloodType: data['bloodType'] ?? '',
      units: (data['units'] ?? 0).toDouble(),
      status: data['status'] ?? 'Available',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toInventoryFirestore(InventoryEntity entity) {
    return {
      'bloodType': entity.bloodType,
      'units': entity.units,
      'status': entity.status,
      'lastUpdated': Timestamp.fromDate(entity.lastUpdated),
    };
  }
}
