import 'package:di_tutorial/core/error/failure.dart';
import 'package:di_tutorial/features/user/data/datasource/user_remote_datasource.dart';
import 'package:di_tutorial/features/user/domain/entities/user.dart';
import 'package:di_tutorial/features/user/domain/repository/user_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remote;

  UserRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, User>> getUser() async {
    try {
      final result = await remote.getUser();
      return right(result);
    } catch (e) {
      return left(Failure('Server error'));
    }
  }
}
