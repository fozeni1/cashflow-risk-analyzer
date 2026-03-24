import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashflow Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String? _login;
  String? _baseUrl;

  void _handleLogin({
    required String login,
    required String baseUrl,
  }) {
    setState(() {
      _login = login;
      _baseUrl = baseUrl;
    });
  }

  void _handleLogout() {
    setState(() {
      _login = null;
      _baseUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_login == null || _baseUrl == null) {
      return LoginScreen(onLogin: _handleLogin);
    }

    return DashboardScreen(
      login: _login!,
      baseUrl: _baseUrl!,
      onLogout: _handleLogout,
    );
  }
}
