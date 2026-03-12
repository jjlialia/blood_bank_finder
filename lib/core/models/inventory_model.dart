import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String bloodType;
  final int units;
  final DateTime lastUpdated;

  InventoryModel({
    required this.bloodType,
    required this.units,
    required this.lastUpdated,
  });

  factory InventoryModel.fromMap(Map<String, dynamic> data) {
    return InventoryModel(
      bloodType: data['blood_type'] ?? '',
      units: data['units'] ?? 0,
      lastUpdated: (data['last_updated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blood_type': bloodType,
      'units': units,
      'last_updated': Timestamp.fromDate(lastUpdated),
    };
  }
}
