import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virex/virex.dart';
import 'package:virex_devtools/virex_devtools.dart';

void main() {
  setUp(() {
    debugResetVirexForTests();
    VirexInspector.instance.debugResetForTests();
  });

  testWidgets('autoSnapshots false does not mutate global inspector flag', (
    WidgetTester tester,
  ) async {
    expect(VirexInspector.instance.autoSnapshotsEnabled, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VirexDevtoolsPanel(autoSnapshots: false, maxRows: 4),
        ),
      ),
    );
    await tester.pump();

    expect(VirexInspector.instance.autoSnapshotsEnabled, isFalse);
  });

  testWidgets('panel enforces maxRows when rendering node table', (
    WidgetTester tester,
  ) async {
    final List<Signal<int>> signals = List<Signal<int>>.generate(
      6,
      (int i) => signal<int>(i, name: 'panel_sig_$i'),
      growable: false,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VirexDevtoolsPanel(autoSnapshots: false, maxRows: 2),
        ),
      ),
    );
    await tester.pump();

    final Finder rows = find.byWidgetPredicate(
      (Widget widget) =>
          widget is Text && (widget.data?.startsWith('#') ?? false),
    );
    expect(rows, findsNWidgets(2));

    for (final Signal<int> node in signals) {
      node.dispose();
    }
  });

  testWidgets('autoSnapshots true toggles on mount and off on dispose', (
    WidgetTester tester,
  ) async {
    expect(VirexInspector.instance.autoSnapshotsEnabled, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: VirexDevtoolsPanel(autoSnapshots: true)),
      ),
    );
    await tester.pump();
    expect(VirexInspector.instance.autoSnapshotsEnabled, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(VirexInspector.instance.autoSnapshotsEnabled, isFalse);
  });
}
