import 'package:di_tutorial/core/error/failure.dart';
import 'package:di_tutorial/features/user/domain/entities/user.dart';
import 'package:di_tutorial/features/user/domain/repository/user_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';

@lazySingleton
class GetUser {
  final UserRepository repository;
  GetUser(this.repository);

  Future<Either<Failure, User>> call() {
    return repository.getUser();
  }
}
