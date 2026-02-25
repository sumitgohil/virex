import 'dart:math';

import 'package:flutter/material.dart';
import 'package:virex/virex.dart';

import '../../shared/rebuild_tracker.dart';

class AuthModule extends StatefulWidget {
  const AuthModule({super.key});

  @override
  State<AuthModule> createState() => _AuthModuleState();
}

final class _AuthModuleState extends State<AuthModule> {
  final Signal<String> _email = signal<String>(
    'dev@virex.dev',
    name: 'auth_email',
  );
  final Signal<String> _password = signal<String>(
    'password123',
    name: 'auth_password',
  );
  late final AsyncSignal<String> _loginState;

  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _loginState = asyncSignal<String>(
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 550));
        _attempt += 1;
        if (_attempt.isOdd && Random().nextBool()) {
          throw StateError('Invalid credentials (simulated)');
        }
        return 'token_${DateTime.now().millisecondsSinceEpoch}';
      },
      autoStart: false,
      maxRetries: 1,
      retryDelay: (_) => const Duration(milliseconds: 300),
      name: 'auth_login',
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _loginState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrackedRebuild(
      name: 'AuthModule',
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Authentication',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _email.value,
                onChanged: (String value) => _email.value = value,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _password.value,
                onChanged: (String value) => _password.value = value,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _loginState.isLoading
                        ? null
                        : _loginState.refresh,
                    child: const Text('Login'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _loginState.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SignalBuilder(
                builder: () {
                  final AsyncState<String> state = _loginState.value;
                  if (state.isLoading) {
                    return const Text('Logging in...');
                  }
                  if (state.error != null) {
                    return Text(
                      'Error: ${state.error}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }
                  if (state.data != null) {
                    return Text('Session token: ${state.data}');
                  }
                  return const Text('Not authenticated');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
