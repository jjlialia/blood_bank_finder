import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalModel {
  final String? id;
  final String name;
  final String email;
  final String islandGroup;
  final String city;
  final String barangay;
  final String address;
  final String contactNumber;
  final double latitude;
  final double longitude;
  final List<String> availableBloodTypes;
  final bool isActive;
  final DateTime createdAt;

  HospitalModel({
    this.id,
    required this.name,
    required this.email,
    required this.islandGroup,
    required this.city,
    required this.barangay,
    required this.address,
    required this.contactNumber,
    required this.latitude,
    required this.longitude,
    required this.availableBloodTypes,
    required this.isActive,
    required this.createdAt,
  });

  factory HospitalModel.fromMap(Map<String, dynamic> data, String documentId) {
    return HospitalModel(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      islandGroup: data['islandGroup'] ?? '',
      city: data['city'] ?? '',
      barangay: data['barangay'] ?? '',
      address: data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      availableBloodTypes: List<String>.from(data['availableBloodTypes'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'islandGroup': islandGroup,
      'city': city,
      'barangay': barangay,
      'address': address,
      'contactNumber': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'availableBloodTypes': availableBloodTypes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
