import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/check_performance_budget.dart <budget.json> <benchmark_output_or_->',
    );
    exit(64);
  }

  final String budgetPath = args[0];
  final String benchmarkArg = args[1];

  final File budgetFile = File(budgetPath);
  if (!budgetFile.existsSync()) {
    stderr.writeln('Budget file not found: $budgetPath');
    exit(66);
  }

  final Map<String, dynamic> budgetJson =
      jsonDecode(budgetFile.readAsStringSync()) as Map<String, dynamic>;
  final Map<String, dynamic> rawBudget =
      budgetJson['max_us_per_op'] as Map<String, dynamic>;
  final Map<String, double> budget = rawBudget.map(
    (String key, dynamic value) => MapEntry(key, (value as num).toDouble()),
  );

  String benchmarkOutput;
  if (benchmarkArg == '-') {
    final ProcessResult result = await Process.run('dart', const <String>[
      'run',
      'benchmark/virex_benchmark.dart',
    ]);
    if (result.exitCode != 0) {
      stderr.writeln(result.stdout);
      stderr.writeln(result.stderr);
      exit(result.exitCode);
    }
    benchmarkOutput = '${result.stdout}';
  } else {
    final File outputFile = File(benchmarkArg);
    if (!outputFile.existsSync()) {
      stderr.writeln('Benchmark output file not found: $benchmarkArg');
      exit(66);
    }
    benchmarkOutput = outputFile.readAsStringSync();
  }

  final Map<String, double> metrics = _parseBenchmarkOutput(benchmarkOutput);
  final List<String> violations = <String>[];

  for (final MapEntry<String, double> entry in budget.entries) {
    final double? current = metrics[entry.key];
    if (current == null) {
      violations.add('Missing metric: ${entry.key}');
      continue;
    }
    if (current > entry.value) {
      violations.add(
        'Metric ${entry.key} exceeded budget '
        '(${current.toStringAsFixed(4)} > ${entry.value.toStringAsFixed(4)})',
      );
    }
  }

  if (violations.isNotEmpty) {
    for (final String violation in violations) {
      stderr.writeln(violation);
    }
    exit(1);
  }

  stdout.writeln('Performance budget check passed.');
}

Map<String, double> _parseBenchmarkOutput(String text) {
  final List<String> lines = const LineSplitter().convert(text);
  String? current;
  final Map<String, double> metrics = <String, double>{};

  for (final String raw in lines) {
    final String line = raw.trimRight();
    if (line.isEmpty) {
      continue;
    }

    if (!line.startsWith(' ') && !line.contains(':')) {
      current = line;
      continue;
    }

    if (current != null && line.trimLeft().startsWith('us_per_op:')) {
      final double? value = double.tryParse(line.split(':').last.trim());
      if (value != null) {
        metrics[current] = value;
      }
      current = null;
    }
  }

  return metrics;
}
