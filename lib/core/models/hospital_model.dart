library;

import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalModel {
  // Unique document ID from Firestore.
  final String? id;
  final String name;
  final String email;

  final String islandGroup;
  final String region;
  final String city;
  final String barangay;
  final String address;

  final String contactNumber;

  // Coordinates
  final double latitude;
  final double longitude;

  final List<String> availableBloodTypes;

  // If false, hidden sa regular user
  final bool isActive;
  final DateTime createdAt;

  HospitalModel({
    this.id,
    required this.name,
    required this.email,
    required this.islandGroup,
    required this.region,
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

  /// Converts Firestore data into a 'HospitalModel' object.
  /// Includes the 'documentId' so we know which specific record to update later.
  factory HospitalModel.fromMap(Map<String, dynamic> data, String documentId) {
    return HospitalModel(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      islandGroup: data['islandGroup'] ?? '',
      region: data['region'] ?? '',
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

  ///Formats the data for saving directly to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'islandGroup': islandGroup,
      'region': region,
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

  /// Formats the data for sending to the FastAPI backend.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'islandGroup': islandGroup,
      'region': region,
      'city': city,
      'barangay': barangay,
      'address': address,
      'contactNumber': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'availableBloodTypes': availableBloodTypes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
