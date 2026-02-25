import 'package:test/test.dart';
import 'package:virex_testkit/virex_testkit.dart';

void main() {
  test('validates metrics against budget', () {
    const VirexPerfBudget budget = VirexPerfBudget(
      maxUsPerOp: <String, double>{'signal write throughput': 0.2},
    );

    final List<String> violations = budget.validate(<String, double>{
      'signal write throughput': 0.15,
    });

    expect(violations, isEmpty);
  });
}
