import 'package:di_tutorial/features/user/presentation/provider/user_provider.dart';
import 'package:di_tutorial/injection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<UserProvider>()..fetch(),
      child: Scaffold(
        appBar: AppBar(title: const Text('User')),
        body: Consumer<UserProvider>(
          builder: (_, p, w) {
            if (p.loading) return const CircularProgressIndicator();
            if (p.error != null) return Text(p.error!);
            return Text(p.user?.name ?? 'No data');
          },
        ),
      ),
    );
  }
}
