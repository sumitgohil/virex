import 'dart:async';

import 'package:flutter/material.dart';
import 'package:virex/virex.dart';

final class RebuildMetrics {
  static final Signal<int> totalRebuilds = signal<int>(
    0,
    name: 'total_rebuilds',
  );
}

class RebuildOverlay extends StatelessWidget {
  const RebuildOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SignalBuilder(
            builder: () => Text(
              'Rebuilds: ${RebuildMetrics.totalRebuilds.value}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class TrackedRebuild extends StatefulWidget {
  const TrackedRebuild({super.key, required this.name, required this.builder});

  final String name;
  final WidgetBuilder builder;

  @override
  State<TrackedRebuild> createState() => _TrackedRebuildState();
}

final class _TrackedRebuildState extends State<TrackedRebuild> {
  int _count = 0;
  bool _pendingCounterTick = false;

  @override
  Widget build(BuildContext context) {
    _count += 1;
    _scheduleGlobalCountTick();

    return Stack(
      children: <Widget>[
        TweenAnimationBuilder<double>(
          key: ValueKey<int>(_count),
          tween: Tween<double>(begin: 1, end: 0),
          duration: const Duration(milliseconds: 120),
          child: widget.builder(context),
          builder: (BuildContext context, double opacity, Widget? child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15 * opacity),
              ),
              child: child,
            );
          },
        ),
        Positioned(
          bottom: 6,
          right: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                '${widget.name}: $_count',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _scheduleGlobalCountTick() {
    if (_pendingCounterTick) {
      return;
    }
    _pendingCounterTick = true;
    scheduleMicrotask(() {
      _pendingCounterTick = false;
      RebuildMetrics.totalRebuilds.value =
          RebuildMetrics.totalRebuilds.value + 1;
    });
  }
}
