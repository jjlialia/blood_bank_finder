/// FILE: hospital_model.dart
///
/// DESCRIPTION:
/// This file defines the 'HospitalModel' class, representing a blood bank or hospital
/// in the system. It tracks its location, contact information, and blood availability.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - Firestore (via 'fromMap'): Fetches from the 'hospitals' collection.
///    - Super Admin UI: When creating or editing a hospital entry.
/// 2. PROCESSING:
///    - Converts geographical coordinates (lat/lng) for map markers.
///    - Manages a list of 'availableBloodTypes'.
///    - Tracks the 'isActive' status to show/hide the hospital from users.
/// 3. SENDS DATA TO:
///    - Firestore (via 'toMap'): For database updates.
///    - FastAPI (via 'toJson'): For administrative actions managed by the backend.
///    - Map/List UI: To show users where they can find or donate blood.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalModel {
  // Unique document ID from Firestore.
  final String? id;
  final String name;
  final String email;

  // Location Hierarchy
  final String islandGroup;
  final String region;
  final String city;
  final String barangay;
  final String address;

  final String contactNumber;

  // Coordinates for placing the hospital on the map.
  final double latitude;
  final double longitude;

  // List of blood types currently stocked (e.g., ["A+", "O-"]).
  final List<String> availableBloodTypes;

  // If false, the hospital is hidden from regular users.
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

  /// STEP: Converts Firestore data into a 'HospitalModel' object.
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

  /// STEP: Formats the data for saving directly to Firestore.
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

  /// STEP: Formats the data for sending to the FastAPI backend.
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
