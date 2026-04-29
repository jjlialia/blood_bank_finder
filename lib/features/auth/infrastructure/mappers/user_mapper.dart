import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
class UserMapper {
  static UserEntity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserEntity(
      uid: doc.id,
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toFirestore(UserEntity entity) {
    return {
      'email': entity.email,
      'role': entity.role,
      'firstName': entity.firstName,
      'lastName': entity.lastName,
      'fatherName': entity.fatherName,
      'mobile': entity.mobile,
      'gender': entity.gender,
      'bloodGroup': entity.bloodGroup,
      'islandGroup': entity.islandGroup,
      'region': entity.region,
      'city': entity.city,
      'barangay': entity.barangay,
      'address': entity.address,
      'hospitalId': entity.hospitalId,
      'isBanned': entity.isBanned,
      'createdAt': Timestamp.fromDate(entity.createdAt),
    };
  }
}
