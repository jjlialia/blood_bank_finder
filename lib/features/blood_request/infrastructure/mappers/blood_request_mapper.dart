import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/blood_request.dart';
class BloodRequestMapper {
  static BloodRequestEntity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BloodRequestEntity(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: data['type'] ?? 'Request',
      bloodType: data['bloodType'] ?? '',
      status: data['status'] ?? 'pending',
      hospitalId: data['hospitalId'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminMessage: data['adminMessage'],
      preferredDate: data['preferredDate'],
      preferredTime: data['preferredTime'],
      patientName: data['patientName'],
      patientHospital: data['patientHospital'],
      urgency: data['urgency'],
      hospitalWard: data['hospitalWard'],
      medicalReason: data['medicalReason'],
      lastDonationDate: data['lastDonationDate'],
    );
  }

  static Map<String, dynamic> toFirestore(BloodRequestEntity entity) {
    return {
      'userId': entity.userId,
      'userName': entity.userName,
      'type': entity.type,
      'bloodType': entity.bloodType,
      'status': entity.status,
      'hospitalId': entity.hospitalId,
      'hospitalName': entity.hospitalName,
      'contactNumber': entity.contactNumber,
      'quantity': entity.quantity,
      'createdAt': Timestamp.fromDate(entity.createdAt),
      if (entity.adminMessage != null) 'adminMessage': entity.adminMessage,
      if (entity.preferredDate != null) 'preferredDate': entity.preferredDate,
      if (entity.preferredTime != null) 'preferredTime': entity.preferredTime,
      if (entity.patientName != null) 'patientName': entity.patientName,
      if (entity.patientHospital != null) 'patientHospital': entity.patientHospital,
      if (entity.urgency != null) 'urgency': entity.urgency,
      if (entity.hospitalWard != null) 'hospitalWard': entity.hospitalWard,
      if (entity.medicalReason != null) 'medicalReason': entity.medicalReason,
      if (entity.lastDonationDate != null) 'lastDonationDate': entity.lastDonationDate,
    };
  }
}
