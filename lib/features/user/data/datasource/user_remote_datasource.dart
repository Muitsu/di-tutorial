import 'package:di_tutorial/core/network/dio_client.dart';
import 'package:injectable/injectable.dart';

import '../models/user_model.dart';

@lazySingleton
class UserRemoteDataSource {
  final DioClient dio;
  UserRemoteDataSource(this.dio);

  Future<UserModel> getUser() async {
    final res = await dio.get('/users/1');
    return UserModel.fromJson(res.data);
  }
}
