import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/audit_log_model.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

class AuthProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  bool _isLoading = false;
  StreamSubscription<UserModel?>? _userSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        _startUserListener(firebaseUser.uid);
      } else {
        _stopUserListener();
      }
    });
  }

  void _startUserListener(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _db.streamUser(uid).listen((userData) {
      _user = userData;
      if (_user?.isBanned ?? false) {
        logout(); // Auto logout if banned
      }
      notifyListeners();
    });
  }

  void _stopUserListener() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _user = null;
    notifyListeners();
  }

  //login
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Admin bypass
      if (email == 'admin@gmail.com' && password == '1234') {
        _user = UserModel(
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
        _isLoading = false;
        notifyListeners();
        return null; // Success
      }

      // Firebase Auth
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      //Fetch Firestore details.
      //delay for web para sure before fetching data
      if (identical(0, 0.0)) {
        // Simple check for web (Dart2JS)
        await Future.delayed(const Duration(milliseconds: 500));
      }

      UserModel? userData;
      try {
        userData = await _db.getUser(credential.user!.uid);
      } catch (e) {
        // If we still get a permission error, it's a structural rule issue.
        print('Firestore getUser error: $e');
        if (e.toString().contains('permission-denied')) {
          return 'Access Denied: Your account exists in Auth but could not be verified in the database. Please contact an administrator.';
        }
        rethrow;
      }

      if (userData == null) {
        await logout();
        _isLoading = false;
        return 'User profile not found. Please complete your registration.';
      }

      if (userData.isBanned) {
        await logout();
        _isLoading = false;
        return 'Your account has been banned. Please contact support.';
      }

      _user = userData;
      _startUserListener(userData.uid);

      // Audit Log: Login
      await _db.logAction(AuditLogModel(
        id: '',
        action: 'USER_LOGIN',
        category: 'Auth',
        description: '${userData.firstName} ${userData.lastName} logged in.',
        userId: userData.uid,
        userName: '${userData.firstName} ${userData.lastName}',
        userRole: userData.role,
        timestamp: DateTime.now(),
      ));

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message ?? 'Authentication failed';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  } //balik na sa login_screen.dart

  Future<void> logout() async {
    await _auth.signOut();
    _stopUserListener();
  }

  //signup
  Future<String?> signup(Map<String, dynamic> data, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: data['email'],
        password: password,
      );

      final newUser = UserModel(
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

      await _api.saveUser(newUser);
      _user = newUser;
      _startUserListener(newUser.uid);

      // Audit Log: Signup
      await _db.logAction(AuditLogModel(
        id: '',
        action: 'USER_SIGNUP',
        category: 'Auth',
        description: 'New account created for ${newUser.email}.',
        userId: newUser.uid,
        userName: '${newUser.firstName} ${newUser.lastName}',
        userRole: newUser.role,
        timestamp: DateTime.now(),
      ));

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message ?? 'Signup failed';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // OTP Flow
  Future<String?> sendOtp(String email) async {
    try {
      await _api.sendOtp(email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> verifyOtp(String email, String otp) async {
    try {
      await _api.verifyOtp(email, otp);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
