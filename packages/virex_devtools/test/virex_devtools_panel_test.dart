import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';
import 'package:virex_devtools/virex_devtools.dart';

void main() {
  testWidgets('panel renders snapshot metadata', (WidgetTester tester) async {
    final Signal<int> value = signal<int>(0, name: 'panel_count');
    final EffectHandle handle = effect(() {
      value.value;
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: VirexDevtoolsPanel())),
    );

    expect(find.textContaining('Virex DevTools'), findsOneWidget);
    expect(find.textContaining('Epoch'), findsOneWidget);

    value.value = 1;
    VirexScheduler.instance.flush();
    await tester.pump();

    expect(find.textContaining('Signals'), findsOneWidget);
    handle.dispose();
  });
}
