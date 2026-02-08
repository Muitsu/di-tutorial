import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/providers.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late UserProvider userProvider;
  @override
  void initState() {
    super.initState();
    userProvider = context.read<UserProvider>();
    userProvider.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: Consumer<UserProvider>(
        builder: (_, p, w) {
          if (p.loading) return const CircularProgressIndicator();
          if (p.error != null) return Text(p.error!);
          return Text(p.user?.name ?? 'No data');
        },
      ),
    );
  }
}
