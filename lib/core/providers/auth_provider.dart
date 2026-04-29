import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/infrastructure/repositories/firebase_auth_repository.dart';
import '../../features/auth/infrastructure/mappers/user_mapper.dart';
import '../../features/auth/application/use_cases/login_use_case.dart';
import '../../features/auth/application/use_cases/auth_use_cases.dart';
import '../../features/super_admin/domain/entities/audit_log.dart';

class AuthProvider with ChangeNotifier {
  // DDD Components
  late final IAuthRepository _repository;
  late final LoginUseCase _loginUseCase;
  late final SignupUseCase _signupUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final SendOtpUseCase _sendOtpUseCase;
  late final VerifyOtpUseCase _verifyOtpUseCase;

  // Legacy/UI State
  UserEntity? _userEntity;
  bool _isLoading = false;
  StreamSubscription<UserEntity?>? _userSubscription;

  // Compatibility getter
  UserEntity? get user => _userEntity;
  UserEntity? get userEntity => _userEntity;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userEntity != null;

  AuthProvider() {
    _repository = FirebaseAuthRepository();
    _loginUseCase = LoginUseCase(_repository);
    _signupUseCase = SignupUseCase(_repository);
    _logoutUseCase = LogoutUseCase(_repository);
    _sendOtpUseCase = SendOtpUseCase(_repository);
    _verifyOtpUseCase = VerifyOtpUseCase(_repository);

    _userSubscription = _repository.onAuthStateChanged.listen((user) {
      _userEntity = user;
      if (_userEntity?.isBanned ?? false) {
        logout();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // login
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _loginUseCase.execute(email, password);
      
      if (result == null) {
        _isLoading = false;
        notifyListeners();
        return 'User profile not found. Please complete your registration.';
      }

      if (result.isBanned) {
        await logout();
        _isLoading = false;
        notifyListeners();
        return 'Your account has been banned. Please contact support.';
      }

      _userEntity = result;

      // Audit Log: Login
      await _logAction(AuditLogEntity(
        id: '',
        action: 'USER_LOGIN',
        category: 'Auth',
        description: '${result.firstName} ${result.lastName} logged in.',
        userId: result.uid,
        userName: '${result.firstName} ${result.lastName}',
        userRole: result.role,
        timestamp: DateTime.now(),
      ));

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _logoutUseCase.execute();
    _userEntity = null;
    notifyListeners();
  }

  // signup
  Future<String?> signup(Map<String, dynamic> data, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _signupUseCase.execute(data, password);
      
      if (result != null) {
        _userEntity = result;

        // Audit Log: Signup
        await _logAction(AuditLogEntity(
          id: '',
          action: 'USER_SIGNUP',
          category: 'Auth',
          description: 'New account created for ${result.email}.',
          userId: result.uid,
          userName: '${result.firstName} ${result.lastName}',
          userRole: result.role,
          timestamp: DateTime.now(),
        ));
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // OTP Flow
  Future<String?> sendOtp(String email) async {
    try {
      await _sendOtpUseCase.execute(email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> verifyOtp(String email, String otp) async {
    try {
      await _verifyOtpUseCase.execute(email, otp);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Internal helper for audit logs to remove DatabaseService dependency
  Future<void> _logAction(AuditLogEntity log) async {
    await FirebaseFirestore.instance.collection('audit_logs').add(log.toFirestore());
  }
}
