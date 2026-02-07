import 'package:di_tutorial/core/network/dio_client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  DioClient dio() => DioClient();
}
