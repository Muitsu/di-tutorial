import 'package:di_tutorial/core/error/failure.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/user.dart';

abstract class UserRepository {
  Future<Either<Failure, User>> getUser();
}
