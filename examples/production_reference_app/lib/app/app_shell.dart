import 'package:flutter/material.dart';
import 'package:virex/virex.dart';

import '../core/app_state.dart';
import '../features/auth/auth_feature.dart';
import '../features/dashboard/dashboard_feature.dart';
import '../features/profile/profile_feature.dart';
import '../features/todos/todos_feature.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

final class _AppShellState extends State<AppShell> {
  final AppState appState = AppState();
  final AuthFeature auth = AuthFeature();
  final DashboardFeature dashboard = DashboardFeature();
  final TodosFeature todos = TodosFeature();
  final ProfileFeature profile = ProfileFeature();

  @override
  void dispose() {
    appState.dispose();
    auth.dispose();
    dashboard.dispose();
    todos.dispose();
    profile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: () => Scaffold(
        appBar: AppBar(title: const Text('Virex Production Reference App')),
        body: _buildBody(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indexOf(appState.activeTab.value),
          onDestinationSelected: (int index) {
            appState.activeTab.value = _tabFromIndex(index);
          },
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(icon: Icon(Icons.checklist), label: 'Todos'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (appState.activeTab.value) {
      case 'dashboard':
        return Center(
          child: SignalBuilder(builder: () => Text(dashboard.summary.value)),
        );
      case 'todos':
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                decoration: const InputDecoration(hintText: 'Add todo'),
                onSubmitted: todos.add,
              ),
            ),
            Expanded(
              child: SignalBuilder(
                builder: () => ListView(
                  children: todos.filtered.value
                      .map((String item) => ListTile(title: Text(item)))
                      .toList(),
                ),
              ),
            ),
          ],
        );
      case 'profile':
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: profile.name.value,
                onChanged: (String value) => profile.name.value = value,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                initialValue: profile.bio.value,
                onChanged: (String value) => profile.bio.value = value,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 8),
              SignalBuilder(
                builder: () => Text(
                  profile.valid.value ? 'Profile valid' : 'Profile invalid',
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  int _indexOf(String tab) {
    switch (tab) {
      case 'dashboard':
        return 0;
      case 'todos':
        return 1;
      case 'profile':
        return 2;
      default:
        return 0;
    }
  }

  String _tabFromIndex(int index) {
    switch (index) {
      case 0:
        return 'dashboard';
      case 1:
        return 'todos';
      case 2:
        return 'profile';
      default:
        return 'dashboard';
    }
  }
}
