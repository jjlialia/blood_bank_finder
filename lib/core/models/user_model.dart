/**
 * FILE: user_model.dart
 * 
 * DESCRIPTION:
 * This file defines the 'UserModel' class, which represents a user in the system.
 * It acts as a structured "container" for all user-related data, such as profile info, 
 * roles (Admin/User), and location.
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - Firestore (via 'fromMap'): Raw data from the database is converted into this object.
 *    - UI Forms: When a user signs up or updates their profile, a new 'UserModel' is created.
 * 2. PROCESSING:
 *    - Validates and provides default values (e.g., 'isBanned' defaults to false).
 *    - Converts Firestore Timestamps into standard Dart DateTime objects.
 * 3. SENDS DATA TO:
 *    - Firestore (via 'toMap'): For direct database writes.
 *    - FastAPI (via 'toJson'): For server-side updates like banning or role changes.
 *    - UI Screens: To display user info (e.g., ProfileScreen, Dashboard).
 * 
 * OUTPUTS:
 * - A structured object that ensures consistency across the entire app.
 */

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // The unique identifier from Firebase Auth.
  final String uid;
  final String email;
  // Defines what the user can see/do ('user', 'superadmin', or 'admin').
  final String role; 
  final String firstName;
  final String lastName;
  final String fatherName;
  final String mobile;
  final String gender;
  final String bloodGroup;
  
  // Geographical Location Data
  final String islandGroup;
  final String region;
  final String city;
  final String barangay;
  final String address;

  // Only populated if the user is a Hospital Admin.
  final String? hospitalId;
  // Restricts app access if set to true.
  final bool isBanned;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.mobile,
    required this.gender,
    required this.bloodGroup,
    required this.islandGroup,
    required this.region,
    required this.city,
    required this.barangay,
    required this.address,
    this.hospitalId,
    required this.isBanned,
    required this.createdAt,
  });

  /**
   * STEP: Converting raw data from Firestore into a usable Flutter object.
   * This handles the "incoming" data flow from the database.
   */
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      fatherName: data['fatherName'] ?? '',
      mobile: data['mobile'] ?? '',
      gender: data['gender'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      islandGroup: data['islandGroup'] ?? '',
      region: data['region'] ?? '',
      city: data['city'] ?? '',
      barangay: data['barangay'] ?? '',
      address: data['address'] ?? '',
      hospitalId: data['hospitalId'],
      isBanned: data['isBanned'] ?? false,
      // Converts Firestore's proprietary Timestamp to Dart's DateTime.
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /**
   * STEP: Converting the object back into a Map for Firestore.
   * Used for direct writes to the 'users' collection.
   */
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'fatherName': fatherName,
      'mobile': mobile,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'islandGroup': islandGroup,
      'region': region,
      'city': city,
      'barangay': barangay,
      'address': address,
      'hospitalId': hospitalId,
      'isBanned': isBanned,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /**
   * STEP: Converting the object into a JSON-compatible Map for the FastAPI backend.
   * Unlike 'toMap', this uses ISO8601 strings for dates instead of Timestamps.
   */
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'fatherName': fatherName,
      'mobile': mobile,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'islandGroup': islandGroup,
      'region': region,
      'city': city,
      'barangay': barangay,
      'address': address,
      'hospitalId': hospitalId,
      'isBanned': isBanned,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
