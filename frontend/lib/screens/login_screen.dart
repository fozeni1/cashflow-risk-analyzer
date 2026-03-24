import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
  });

  final void Function({
    required String login,
    required String baseUrl,
  }) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController(
    text: _defaultBaseUrl,
  );

  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool createUser}) async {
    final login = _loginController.text.trim();
    final baseUrl = _baseUrlController.text.trim();

    if (login.isEmpty || baseUrl.isEmpty) {
      _showMessage('Enter login and backend URL.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final api = ApiService(baseUrl: baseUrl);

    try {
      if (createUser) {
        await api.createUser(login);
      }
      await api.login(login);

      if (!mounted) {
        return;
      }

      widget.onLogin(
        login: login,
        baseUrl: baseUrl,
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Failed to reach backend.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cashflow Prototype',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Simple client for users, wallets, income and expense.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Backend URL',
                        hintText: 'http://127.0.0.1:8000',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _loginController,
                      decoration: const InputDecoration(
                        labelText: 'Login',
                        hintText: 'egor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _helperText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () => _submit(createUser: false),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _submit(createUser: true),
                      child: const Text('Create user and login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const String _defaultBaseUrl = kIsWeb
    ? 'http://127.0.0.1:8000'
    : 'http://127.0.0.1:8000';

const String _helperText =
    'Authorization is just Bearer <login>. On Android emulator use '
    'http://10.0.2.2:8000 instead of 127.0.0.1.';
