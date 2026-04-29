import '../entities/user.dart';

abstract class IAuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity?> signup(Map<String, dynamic> data, String password);
  Future<void> logout();
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String otp);
  Stream<UserEntity?> get onAuthStateChanged;
}
