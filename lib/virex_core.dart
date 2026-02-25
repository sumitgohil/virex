// ignore_for_file: unnecessary_library_name

/// Core-only export for pure Dart and server-side usage.
///
/// This library intentionally excludes Flutter widgets/bindings.
library virex_core;

export 'src/core/async_signal.dart';
export 'src/core/batch.dart';
export 'src/core/computed.dart';
export 'src/core/dependency_graph.dart'
    show GraphInvariantIssue, GraphInvariantResult, NodeKind;
export 'src/core/effect.dart';
export 'src/core/runtime_config.dart';
export 'src/core/scheduler.dart';
export 'src/core/signal.dart';
export 'src/core/testing.dart' show debugResetVirexForTests;
export 'src/ecosystem/plugin_compatibility_report.dart';
export 'src/debug/inspector.dart';
export 'src/debug/logger.dart';
export 'src/migration/migration_report.dart';
