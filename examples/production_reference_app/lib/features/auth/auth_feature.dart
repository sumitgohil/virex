import 'package:virex/virex.dart';

final class AuthFeature {
  AuthFeature();

  final Signal<String> email = signal<String>('', name: 'auth_email');
  final Signal<String> password = signal<String>('', name: 'auth_password');

  late final Computed<bool> canSubmit = computed<bool>(
    () => email.value.contains('@') && password.value.length >= 8,
    name: 'auth_can_submit',
  );

  Future<bool> login() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return canSubmit.value;
  }

  void dispose() {
    email.dispose();
    password.dispose();
    canSubmit.dispose();
  }
}
