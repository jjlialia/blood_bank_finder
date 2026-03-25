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

  ///  gkan sa firebase padung sa app. if mobasa para masabtan og ma show sa screen.
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

  /// gkan sa app padung sa firebase. if mag update sa status. save daretso without fastapi
  ///gkan sa taas nga model i unbox para masabtan sa firebase.
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

  /// gkan sa app padung sa fastapi (http request, server). if mag save og request.
  /// gkan sa taas nga model i unbox para masabtan sa fastapi.
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
