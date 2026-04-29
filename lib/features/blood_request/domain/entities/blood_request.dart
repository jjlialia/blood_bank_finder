class BloodRequestEntity {
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
  final String? preferredDate;
  final String? preferredTime;
  final String? patientName;
  final String? patientHospital;
  final String? urgency;
  final String? hospitalWard;
  final String? medicalReason;
  final String? lastDonationDate;

  BloodRequestEntity({
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
    this.preferredDate,
    this.preferredTime,
    this.patientName,
    this.patientHospital,
    this.urgency,
    this.hospitalWard,
    this.medicalReason,
    this.lastDonationDate,
  });

  bool get isRequest => type == 'Request';
  bool get isDonation => type == 'Donate';
  bool get isPending => status == 'pending';
}
