import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final String outputPath = args.isNotEmpty
      ? args.first
      : 'benchmark/baseline.json';

  final ProcessResult result = await Process.run('dart', const <String>[
    'run',
    'benchmark/virex_benchmark.dart',
  ]);

  if (result.exitCode != 0) {
    stderr.writeln(result.stdout);
    stderr.writeln(result.stderr);
    exit(result.exitCode);
  }

  final Map<String, double> metrics = _parseUsPerOp('${result.stdout}');

  final Map<String, Object?> payload = <String, Object?>{
    'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
    'metrics_us_per_op': metrics,
  };

  final File out = File(outputPath);
  out.createSync(recursive: true);
  out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(payload));

  stdout.writeln('Wrote benchmark baseline: ${out.path}');
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
