class UserEntity {
  final String uid;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String fatherName;
  final String mobile;
  final String gender;
  final String bloodGroup;
  final String islandGroup;
  final String region;
  final String city;
  final String barangay;
  final String address;
  final String? hospitalId;
  final bool isBanned;
  final DateTime createdAt;

  UserEntity({
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

  String get fullName => '$firstName $lastName';
}
