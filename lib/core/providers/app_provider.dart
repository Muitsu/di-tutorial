import 'package:di_tutorial/core/di/injection.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'providers.dart';

//REGISTER PROVIDERS HERE
class AppProviders {
  static List<SingleChildWidget> get providers => _providers;
  //Register provider here
  static final List<SingleChildWidget> _providers = [
    //UserProvider
    ChangeNotifierProvider(create: (_) => sl<UserProvider>()),
  ];
}

T sl<T extends Object>() => getIt<T>();
