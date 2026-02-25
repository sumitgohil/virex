import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/check_benchmark_regression.dart <baseline.json> [maxRegressionPercent]',
    );
    exit(64);
  }

  final String baselinePath = args[0];
  final double maxRegressionPercent = args.length >= 2
      ? (double.tryParse(args[1]) ?? 25)
      : 25;

  final File baselineFile = File(baselinePath);
  if (!baselineFile.existsSync()) {
    stderr.writeln('Baseline file not found: $baselinePath');
    exit(66);
  }

  final Map<String, dynamic> baselineJson =
      jsonDecode(baselineFile.readAsStringSync()) as Map<String, dynamic>;

  final Map<String, dynamic> rawMetrics =
      baselineJson['metrics_us_per_op'] as Map<String, dynamic>;
  final Map<String, double> baseline = rawMetrics.map(
    (String key, dynamic value) => MapEntry(key, (value as num).toDouble()),
  );

  final ProcessResult run = await Process.run('dart', const <String>[
    'run',
    'benchmark/virex_benchmark.dart',
  ]);

  if (run.exitCode != 0) {
    stderr.writeln(run.stdout);
    stderr.writeln(run.stderr);
    exit(run.exitCode);
  }

  final Map<String, double> current = _parseUsPerOp('${run.stdout}');

  bool failed = false;
  for (final MapEntry<String, double> entry in baseline.entries) {
    final double? currentUs = current[entry.key];
    if (currentUs == null) {
      stderr.writeln('Missing benchmark metric in current run: ${entry.key}');
      failed = true;
      continue;
    }

    final double baselineUs = entry.value;
    final double regressionPercent = baselineUs == 0
        ? 0
        : ((currentUs - baselineUs) / baselineUs) * 100;

    stdout.writeln(
      '${entry.key}: baseline=${baselineUs.toStringAsFixed(4)}us '
      'current=${currentUs.toStringAsFixed(4)}us '
      'delta=${regressionPercent.toStringAsFixed(2)}%',
    );

    if (regressionPercent > maxRegressionPercent) {
      stderr.writeln(
        'Regression detected for ${entry.key}: ${regressionPercent.toStringAsFixed(2)}% '
        '(allowed ${maxRegressionPercent.toStringAsFixed(2)}%).',
      );
      failed = true;
    }
  }

  if (failed) {
    exit(1);
  }
}

Map<String, double> _parseUsPerOp(String text) {
  final List<String> lines = const LineSplitter().convert(text);

  String? currentLabel;
  final Map<String, double> result = <String, double>{};

  for (final String raw in lines) {
    final String line = raw.trimRight();
    if (line.isEmpty) {
      continue;
    }

    if (!line.startsWith(' ') && !line.contains(':')) {
      currentLabel = line;
      continue;
    }

    if (currentLabel != null && line.trimLeft().startsWith('us_per_op:')) {
      final String valueText = line.split(':').last.trim();
      final double? parsed = double.tryParse(valueText);
      if (parsed != null) {
        result[currentLabel] = parsed;
      }
      currentLabel = null;
    }
  }

  if (result.isEmpty) {
    throw StateError('No benchmark us_per_op metrics were parsed.');
  }

  return result;
}
