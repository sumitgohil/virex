import 'package:flutter/material.dart';
import 'package:virex/virex.dart';
import 'package:virex_devtools/virex_devtools.dart';
import 'package:virex_persist/virex_persist.dart';

import 'modules/auth/auth_module.dart';
import 'modules/cart/cart_module.dart';
import 'modules/dashboard/dashboard_module.dart';
import 'modules/infinite_list/infinite_list_module.dart';
import 'modules/performance/performance_module.dart';
import 'modules/profile/profile_module.dart';
import 'modules/theme/theme_module.dart';
import 'modules/todos/todos_module.dart';
import 'shared/rebuild_tracker.dart';

void main() {
  runApp(const VirexExampleApp());
}

class VirexExampleApp extends StatefulWidget {
  const VirexExampleApp({super.key});

  @override
  State<VirexExampleApp> createState() => _VirexExampleAppState();
}

final class _VirexExampleAppState extends State<VirexExampleApp> {
  final Signal<int> _tab = signal<int>(0, name: 'tab_index');
  final Signal<bool> _isDark = signal<bool>(false, name: 'global_theme');
  final Signal<bool> _themeHydrated = signal<bool>(false, name: 'theme_ready');
  final Signal<bool> _showDevtools = signal<bool>(
    false,
    name: 'show_devtools_panel',
  );
  final MemoryVirexStore _themeStore = MemoryVirexStore();

  PersistedSignal<bool>? _persistedTheme;
  EffectHandle? _themeMirrorEffect;

  static const List<String> _titles = <String>[
    'Auth',
    'Dashboard',
    'Todos',
    'Cart',
    'Theme',
    'Profile',
    'Infinite',
    'Performance',
  ];

  @override
  void initState() {
    super.initState();
    _initThemePersistence();
  }

  Future<void> _initThemePersistence() async {
    final PersistedSignal<bool> persisted = await PersistedSignal.create<bool>(
      key: 'global_theme_dark',
      initial: false,
      store: _themeStore,
      toStorage: (bool value) => value ? '1' : '0',
      fromStorage: (String raw) => raw == '1',
      writeDebounce: const Duration(milliseconds: 100),
      name: 'persisted_global_theme',
    );

    if (!mounted) {
      persisted.dispose();
      return;
    }

    _persistedTheme = persisted;
    _isDark.value = persisted.node.value;
    _themeMirrorEffect = effect(() {
      final bool next = _isDark.value;
      if (persisted.node.value != next) {
        persisted.node.value = next;
      }
    });
    _themeHydrated.value = true;
  }

  @override
  void dispose() {
    _themeMirrorEffect?.dispose();
    _persistedTheme?.dispose();
    _tab.dispose();
    _isDark.dispose();
    _themeHydrated.dispose();
    _showDevtools.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: () {
        final ThemeData theme = _isDark.value
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Virex Battle Test',
          theme: theme,
          home: Scaffold(
            appBar: AppBar(
              title: Text('Virex • ${_titles[_tab.value]}'),
              actions: <Widget>[
                IconButton(
                  onPressed: () => _showDevtools.value = !_showDevtools.value,
                  icon: const Icon(Icons.bug_report),
                  tooltip: _showDevtools.value
                      ? 'Hide DevTools'
                      : 'Show DevTools',
                ),
                IconButton(
                  onPressed: () => RebuildMetrics.totalRebuilds.value = 0,
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Reset rebuild count',
                ),
              ],
            ),
            body: Stack(
              children: <Widget>[
                _buildTab(_tab.value),
                const RebuildOverlay(),
                if (!_themeHydrated.value)
                  const Positioned(
                    top: 56,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Color(0xFFFFF8E1),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Hydrating persisted theme signal...'),
                      ),
                    ),
                  ),
                if (_showDevtools.value)
                  const Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: SizedBox(height: 210, child: VirexDevtoolsPanel()),
                  ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab.value,
              onDestinationSelected: (int index) => _tab.value = index,
              destinations: const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.lock), label: 'Auth'),
                NavigationDestination(
                  icon: Icon(Icons.dashboard),
                  label: 'Dash',
                ),
                NavigationDestination(
                  icon: Icon(Icons.checklist),
                  label: 'Todos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Cart',
                ),
                NavigationDestination(
                  icon: Icon(Icons.palette),
                  label: 'Theme',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
                NavigationDestination(
                  icon: Icon(Icons.list),
                  label: 'Infinite',
                ),
                NavigationDestination(icon: Icon(Icons.speed), label: 'Perf'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const AuthModule();
      case 1:
        return const DashboardModule();
      case 2:
        return const TodosModule();
      case 3:
        return const CartModule();
      case 4:
        return ThemeModule(isDark: _isDark);
      case 5:
        return const ProfileModule();
      case 6:
        return const InfiniteListModule();
      case 7:
        return const PerformanceModule();
      default:
        return const SizedBox.shrink();
    }
  }
}
