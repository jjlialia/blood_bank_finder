import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'dart:convert';

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

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Admin Bypass Logic
      if (email == 'admin@gmail.com' && password == '1234') {
        // ... (Keep existing admin bypass for now or update it)
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
          city: 'Cloud',
          barangay: 'Cloud',
          address: 'Mainframe',
          isBanned: false,
          createdAt: DateTime.now(),
        );
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // 2. FastAPI Backend Login
      final response = await _api.post('/auth/login', {
        'username': email, // FastAPI OAuth2PasswordRequestForm uses 'username'
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        await _api.saveToken(token);

        // 3. Normal Firebase Auth (Keep for sync if needed, or remove later)
        UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final userData = await _db.getUser(credential.user!.uid);
        if (userData == null) {
          await logout();
          _isLoading = false;
          return 'User data not found.';
        }

        if (userData.isBanned) {
          await logout();
          _isLoading = false;
          return 'Your account has been banned.';
        }

        _user = userData;
        _startUserListener(userData.uid);
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _isLoading = false;
        notifyListeners();
        return 'Backend authentication failed: ${response.statusCode}';
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message ?? 'Authentication failed';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _api.deleteToken();
    _stopUserListener();
  }

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
        city: data['city'] ?? '',
        barangay: data['barangay'] ?? '',
        address: data['address'] ?? '',
        isBanned: false,
        createdAt: DateTime.now(),
      );

      await _db.saveUser(newUser);
      _user = newUser;
      _startUserListener(newUser.uid);

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
}
