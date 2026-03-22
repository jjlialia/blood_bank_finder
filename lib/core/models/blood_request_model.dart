library;

import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequestModel {
  // Unique ID for the specific request.
  final String? id;
  // The person making the request/donation.
  final String userId;
  final String userName;

  // The action type: 'Request' (Patient Needs) vs 'Donate' (Donor Gives).
  final String type;
  final String bloodType;

  // Current state: 'pending', 'approved', 'completed', or 'rejected'.
  final String status;

  // The hospital where the request is handled.
  final String hospitalId;
  final String hospitalName;

  final String contactNumber;
  final double quantity; // E.g., 500ml or 1 unit.
  final DateTime createdAt;

  // Optional feedback from an admin (e.g., "Bring your ID").
  final String? adminMessage;

  BloodRequestModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.bloodType,
    required this.status,
    required this.hospitalId,
    required this.hospitalName,
    required this.contactNumber,
    required this.quantity,
    required this.createdAt,
    this.adminMessage,
  });

  /// STEP: Reconstructs a 'BloodRequestModel' from Firestore data.
  factory BloodRequestModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return BloodRequestModel(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: data['type'] ?? '',
      bloodType: data['bloodType'] ?? '',
      status: data['status'] ?? 'pending',
      hospitalId: data['hospitalId'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      adminMessage: data['adminMessage'],
    );
  }

  /// STEP: Prepares data for Firestore database updates.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type,
      'bloodType': bloodType,
      'status': status,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'contactNumber': contactNumber,
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminMessage': adminMessage,
    };
  }

  /// STEP: Prepares data for the FastAPI backend.
  /// This is the primary way NEW requests are saved to the system.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type,
      'bloodType': bloodType,
      'status': status,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'contactNumber': contactNumber,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
      'adminMessage': adminMessage,
    };
  }
}

/// FILE: blood_request_model.dart
///
/// DESCRIPTION:
/// This file defines the 'BloodRequestModel', which tracks a single event of
/// requesting or donating blood. It connects a User to a Hospital.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - Request/Donate UI: Users fill out forms to create these requests.
///    - Firestore: Fetched for history views and admin dashboards.
/// 2. PROCESSING:
///    - Categorizes the action as either 'Request' (needing blood) or 'Donate' (giving blood).
///    - Tracks the 'status' (pending -> approved -> completed/rejected).
///    - Stores administrative feedback via 'adminMessage'.
/// 3. SENDS DATA TO:
///    - FastAPI (via 'toJson'): ALL new requests are sent through the API for security.
///    - Firestore: For updates (status changes) or historical record keeping.
///    - Notifications: When a status changes, this data is used to alert the user.
