import 'dart:async';

import 'package:flutter/material.dart';
import 'package:virex/virex.dart';

/// Embeddable panel that visualizes Virex graph snapshots live.
class VirexDevtoolsPanel extends StatefulWidget {
  const VirexDevtoolsPanel({
    super.key,
    this.autoSnapshots = true,
    this.maxRows = 8,
  });

  /// When true, the panel requests auto-snapshots after flush cycles.
  final bool autoSnapshots;

  /// Maximum node rows to render in the summary table.
  final int maxRows;

  @override
  State<VirexDevtoolsPanel> createState() => _VirexDevtoolsPanelState();
}

final class _VirexDevtoolsPanelState extends State<VirexDevtoolsPanel> {
  final VirexInspector _inspector = VirexInspector.instance;

  StreamSubscription<VirexGraphSnapshot>? _subscription;
  VirexGraphSnapshot? _snapshot;
  bool _invariantsOk = true;

  @override
  void initState() {
    super.initState();

    _inspector.registerVmServiceExtensions();
    if (widget.autoSnapshots) {
      _inspector.setAutoSnapshots(enabled: true);
    }

    _subscription = _inspector.snapshots.listen((VirexGraphSnapshot snapshot) {
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _invariantsOk = _inspector.debugCheckInvariants();
      });
    });

    _snapshot = _inspector.snapshot();
    _invariantsOk = _inspector.debugCheckInvariants();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    if (widget.autoSnapshots) {
      _inspector.setAutoSnapshots(enabled: false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VirexGraphSnapshot? snapshot = _snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final int signalCount = snapshot.nodes
        .where((VirexNodeSnapshot node) => node.kind == NodeKind.signal)
        .length;
    final int computedCount = snapshot.nodes
        .where((VirexNodeSnapshot node) => node.kind == NodeKind.computed)
        .length;
    final int effectCount = snapshot.nodes
        .where((VirexNodeSnapshot node) => node.kind == NodeKind.effect)
        .length;

    final List<VirexNodeSnapshot> rows = snapshot.nodes
        .take(widget.maxRows)
        .toList(growable: false);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Virex DevTools',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _pill('Epoch ${snapshot.flushEpoch}'),
                _pill('Phase ${snapshot.phase.name}'),
                _pill('Signals $signalCount'),
                _pill('Computed $computedCount'),
                _pill('Effects $effectCount'),
                _pill(_invariantsOk ? 'Invariants OK' : 'Invariants FAIL'),
              ],
            ),
            const SizedBox(height: 10),
            for (final VirexNodeSnapshot node in rows)
              Text(
                '#${node.id} ${node.kind.name} '
                'deps=${node.dependencies.length} '
                'subs=${node.subscribers.length} '
                'dirty=${node.dirty}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(text),
      ),
    );
  }
}
