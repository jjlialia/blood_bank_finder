import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class SignupUseCase {
  final IAuthRepository repository;

  SignupUseCase(this.repository);

  Future<UserEntity?> execute(Map<String, dynamic> data, String password) async {
    return await repository.signup(data, password);
  }
}

class LogoutUseCase {
  final IAuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> execute() async {
    await repository.logout();
  }
}

class SendOtpUseCase {
  final IAuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<void> execute(String email) async {
    await repository.sendOtp(email);
  }
}

class VerifyOtpUseCase {
  final IAuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<void> execute(String email, String otp) async {
    await repository.verifyOtp(email, otp);
  }
}
