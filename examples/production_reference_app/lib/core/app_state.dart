import 'package:virex/virex.dart';

/// App-level state container shared across feature modules.
final class AppState {
  AppState();

  final Signal<bool> isAuthenticated = signal<bool>(false, name: 'auth_flag');
  final Signal<String> activeTab = signal<String>(
    'dashboard',
    name: 'active_tab',
  );

  void dispose() {
    isAuthenticated.dispose();
    activeTab.dispose();
  }
}
