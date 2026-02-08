// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:di_tutorial/core/network/dio_client.dart' as _i961;
import 'package:di_tutorial/core/network/dio_module.dart' as _i862;
import 'package:di_tutorial/features/user/data/datasource/user_remote_datasource.dart'
    as _i330;
import 'package:di_tutorial/features/user/data/repository/user_repository_impl.dart'
    as _i601;
import 'package:di_tutorial/features/user/domain/repository/user_repository.dart'
    as _i689;
import 'package:di_tutorial/features/user/domain/usecase/get_user.dart'
    as _i737;
import 'package:di_tutorial/features/user/presentation/provider/user_provider.dart'
    as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    gh.lazySingleton<_i961.DioClient>(() => networkModule.dio());
    gh.lazySingleton<_i330.UserRemoteDataSource>(
      () => _i330.UserRemoteDataSource(gh<_i961.DioClient>()),
    );
    gh.lazySingleton<_i689.UserRepository>(
      () => _i601.UserRepositoryImpl(gh<_i330.UserRemoteDataSource>()),
    );
    gh.lazySingleton<_i737.GetUser>(
      () => _i737.GetUser(gh<_i689.UserRepository>()),
    );
    gh.factory<_i59.UserProvider>(() => _i59.UserProvider(gh<_i737.GetUser>()));
    return this;
  }
}

class _$NetworkModule extends _i862.NetworkModule {}
