import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/dependency_graph.dart';
import '../core/runtime.dart';

/// Flutter widget that rebuilds only when accessed reactive dependencies change.
class SignalBuilder extends StatefulWidget {
  const SignalBuilder({super.key, required this.builder, this.debugLabel});

  /// Builder callback that may read signals/computeds.
  final Widget Function() builder;

  /// Optional debug label attached to the observer node.
  final String? debugLabel;

  @override
  State<SignalBuilder> createState() => _SignalBuilderState();
}

final class _SignalBuilderState extends State<SignalBuilder> {
  late final int _nodeId;

  Widget? _child;
  bool _frameScheduled = false;

  @override
  void initState() {
    super.initState();
    _nodeId = ReactiveRuntime.instance.createNode(
      NodeKind.effect,
      name: widget.debugLabel,
    );
    ReactiveRuntime.instance.scheduler.registerEffectRunner(
      _nodeId,
      _onInvalidated,
    );
    _runBuilderAndTrack();
  }

  @override
  void didUpdateWidget(covariant SignalBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builder != widget.builder) {
      _runBuilderAndTrack();
    }
  }

  @override
  void dispose() {
    ReactiveRuntime.instance.disposeNode(_nodeId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _child ?? const SizedBox.shrink();
  }

  void _onInvalidated() {
    if (!mounted || _frameScheduled) {
      return;
    }

    _frameScheduled = true;
    final SchedulerBinding binding = SchedulerBinding.instance;

    if (binding.schedulerPhase == SchedulerPhase.idle) {
      binding.scheduleFrameCallback((_) => _rebuildInFrame());
      binding.ensureVisualUpdate();
      return;
    }

    binding.addPostFrameCallback((_) => _rebuildInFrame());
  }

  void _rebuildInFrame() {
    if (!mounted) {
      _frameScheduled = false;
      return;
    }

    setState(() {
      _runBuilderAndTrack();
      _frameScheduled = false;
    });
  }

  void _runBuilderAndTrack() {
    try {
      _child = ReactiveRuntime.instance.collectDependenciesWithResult<Widget>(
        _nodeId,
        widget.builder,
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'virex',
          context: ErrorDescription('while building SignalBuilder'),
        ),
      );
      _child = const SizedBox.shrink();
    }
  }
}
