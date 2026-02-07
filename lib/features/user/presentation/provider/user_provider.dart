import 'package:di_tutorial/features/user/domain/entities/user.dart';
import 'package:di_tutorial/features/user/domain/usecase/get_user.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@injectable
class UserProvider extends ChangeNotifier {
  final GetUser getUser;

  UserProvider(this.getUser);

  bool loading = false;
  String? error;
  User? user;

  Future<void> fetch() async {
    loading = true;
    error = null;
    notifyListeners();

    final result = await getUser();

    result.fold((l) => error = l.message, (r) => user = r);

    loading = false;
    notifyListeners();
  }
}
