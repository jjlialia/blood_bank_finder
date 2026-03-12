import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequestModel {
  final String? id;
  final String userId;
  final String userName;
  final String type; // 'Request' or 'Donate'
  final String bloodType;
  final String status; // 'pending', 'approved', 'completed', 'rejected'
  final String hospitalId;
  final String hospitalName;
  final String contactNumber;
  final double quantity;
  final DateTime createdAt;
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
