import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryEntity {
  final String? id;
  final String bloodType;
  final double units;
  final String status;
  final DateTime lastUpdated;

  InventoryEntity({
    this.id,
    required this.bloodType,
    required this.units,
    required this.status,
    required this.lastUpdated,
  });

  bool get isLowStock => units < 5;

  factory InventoryEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryEntity(
      id: doc.id,
      bloodType: data['bloodType'] ?? '',
      units: (data['units'] ?? 0).toDouble(),
      status: data['status'] ?? 'Available',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bloodType': bloodType,
      'units': units,
      'status': status,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
