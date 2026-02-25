import 'package:flutter/material.dart';
import 'package:virex/virex.dart';

import '../../shared/rebuild_tracker.dart';

class ThemeModule extends StatelessWidget {
  const ThemeModule({super.key, required this.isDark});

  final Signal<bool> isDark;

  @override
  Widget build(BuildContext context) {
    return TrackedRebuild(
      name: 'ThemeModule',
      builder: (_) {
        return Center(
          child: SignalBuilder(
            builder: () {
              return SwitchListTile(
                title: const Text('Global dark theme signal'),
                subtitle: Text(isDark.value ? 'Dark mode' : 'Light mode'),
                value: isDark.value,
                onChanged: (bool value) => isDark.value = value,
              );
            },
          ),
        );
      },
    );
  }
}
