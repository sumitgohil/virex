import 'dart:convert';

/// Performance budget definition for benchmark metrics.
final class VirexPerfBudget {
  const VirexPerfBudget({required this.maxUsPerOp});

  final Map<String, double> maxUsPerOp;

  factory VirexPerfBudget.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> raw =
        json['max_us_per_op'] as Map<String, dynamic>;
    return VirexPerfBudget(
      maxUsPerOp: raw.map(
        (String key, dynamic value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'max_us_per_op': maxUsPerOp};
  }

  static Map<String, double> parseBenchmarkOutput(String text) {
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

  List<String> validate(Map<String, double> currentMetrics) {
    final List<String> violations = <String>[];

    for (final MapEntry<String, double> budget in maxUsPerOp.entries) {
      final double? current = currentMetrics[budget.key];
      if (current == null) {
        violations.add('Missing metric: ${budget.key}');
        continue;
      }
      if (current > budget.value) {
        violations.add(
          'Metric ${budget.key} exceeded budget '
          '(${current.toStringAsFixed(4)} > ${budget.value.toStringAsFixed(4)})',
        );
      }
    }

    return violations;
  }
}
