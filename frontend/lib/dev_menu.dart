import 'package:flutter/material.dart';

class DevScreenMenu extends StatelessWidget {
  const DevScreenMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = {
      '/splash': 'Splash Screen',
      '/welcome': 'Welcome Screen (Initial)',
      '/login': 'Login Screen',
      '/signup': 'Signup Flow',
      '/home': 'Home/Dashboard',
      '/create_wallet': 'Create Wallet',
      '/send-money': 'Send Money/Transaction',
      '/deposits': 'Deposits/Receive History',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚠️ DEV MODE - Screen Checkup ⚠️'),
        backgroundColor: Colors.red[900],
      ),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes.keys.elementAt(index);
          final name = routes.values.elementAt(index);
          return ListTile(
            title: Text(name),
            subtitle: Text(route),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, route);
            },
          );
        },
      ),
    );
  }
}
