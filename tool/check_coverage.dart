import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/check_coverage.dart <lcov.info> <minPercent>',
    );
    exit(64);
  }

  final File lcovFile = File(args[0]);
  final double minPercent = double.tryParse(args[1]) ?? 0;

  if (!lcovFile.existsSync()) {
    stderr.writeln('Coverage file not found: ${lcovFile.path}');
    exit(66);
  }

  int totalLines = 0;
  int coveredLines = 0;

  for (final String line in lcovFile.readAsLinesSync()) {
    if (!line.startsWith('DA:')) {
      continue;
    }

    final List<String> parts = line.substring(3).split(',');
    if (parts.length != 2) {
      continue;
    }

    totalLines += 1;
    final int hits = int.tryParse(parts[1]) ?? 0;
    if (hits > 0) {
      coveredLines += 1;
    }
  }

  if (totalLines == 0) {
    stderr.writeln('No coverage lines found in ${lcovFile.path}.');
    exit(1);
  }

  final double percent = coveredLines * 100 / totalLines;
  stdout.writeln(
    'Coverage: ${percent.toStringAsFixed(2)}% ($coveredLines/$totalLines)',
  );

  if (percent < minPercent) {
    stderr.writeln(
      'Coverage ${percent.toStringAsFixed(2)}% is below required ${minPercent.toStringAsFixed(2)}%.',
    );
    exit(1);
  }
}
