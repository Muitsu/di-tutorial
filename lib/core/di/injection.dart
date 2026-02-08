import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

// dart run build_runner build --delete-conflicting-outputs

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
