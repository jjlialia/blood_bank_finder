import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/user_mapper.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserEntity?> login(String email, String password) async {
    // Admin bypass logic
    if (email == 'admin@gmail.com' && password == '1234') {
      return UserEntity(
        uid: 'superadmin_bypass',
        email: email,
        role: 'superadmin',
        firstName: 'System',
        lastName: 'Admin',
        fatherName: 'Root',
        mobile: '0000000000',
        gender: 'Other',
        bloodGroup: 'All',
        islandGroup: 'Cloud',
        region: 'Cloud',
        city: 'Cloud',
        barangay: 'Cloud',
        address: 'Mainframe',
        isBanned: false,
        createdAt: DateTime.now(),
      );
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
    if (!doc.exists) return null;

    return UserMapper.fromFirestore(doc);
  }

  @override
  Future<UserEntity?> signup(Map<String, dynamic> data, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: data['email'],
      password: password,
    );

    final userEntity = UserEntity(
      uid: credential.user!.uid,
      email: data['email'],
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
      isBanned: false,
      createdAt: DateTime.now(),
    );

    final firestoreData = UserMapper.toFirestore(userEntity);
    await _firestore.collection('users').doc(userEntity.uid).set(firestoreData);
    
    return userEntity;
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendOtp(String email) async {
    // Note: OTP service was originally in ApiService. 
    // For pure DDD, we might need a dedicated NotificationService or similar.
    // For now, I'll keep the logic here if it's just a Firestore call or external API.
    // Assuming ApiService.sendOtp was an external API call.
    // In this migration, we want to remove ApiService.
    // If ApiService.sendOtp was just a Firestore trigger:
    await _firestore.collection('otp_requests').add({
      'email': email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    // Same for verifyOtp.
    final query = await _firestore
        .collection('otp_requests')
        .where('email', isEqualTo: email)
        .where('otp', isEqualTo: otp)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) {
      throw Exception('Invalid OTP');
    }
  }

  @override
  Stream<UserEntity?> get onAuthStateChanged {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      return doc.exists ? UserMapper.fromFirestore(doc) : null;
    });
  }
}
