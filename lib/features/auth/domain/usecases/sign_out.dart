import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/auth/domain/repositories/auth_repository.dart';

class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
