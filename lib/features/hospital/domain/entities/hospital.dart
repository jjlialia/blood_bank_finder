class HospitalEntity {
  final String? id;
  final String name;
  final String email;
  final String islandGroup;
  final String region;
  final String city;
  final String barangay;
  final String address;
  final String contactNumber;
  final double latitude;
  final double longitude;
  final List<String> availableBloodTypes;
  final bool isActive;
  final DateTime createdAt;

  HospitalEntity({
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
}
