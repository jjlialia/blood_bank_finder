import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class LoginUseCase {
  final IAuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity?> execute(String email, String password) async {
    return await repository.login(email, password);
  }
}
