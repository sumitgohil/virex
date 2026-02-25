import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_riverpod_bridge/virex_riverpod_bridge.dart';

void main() {
  setUp(debugResetVirexForTests);

  test('provider listener sees deterministic signal updates', () {
    final Signal<int> counter = signal<int>(0);
    final provider = riverpodSignalProvider<int>(counter);
    final ProviderContainer container = ProviderContainer();
    final List<int> observed = <int>[];

    final ProviderSubscription<int> sub = container.listen<int>(
      provider,
      (int? previous, int next) => observed.add(next),
      fireImmediately: true,
    );

    counter.value = 1;
    VirexScheduler.instance.flush();
    counter.value = 2;
    VirexScheduler.instance.flush();

    expect(container.read(provider), 2);
    expect(observed, containsAllInOrder(<int>[0, 1, 2]));

    sub.close();
    container.dispose();
    counter.dispose();
  });

  test('signalFromStateNotifier removes listener after signal dispose', () {
    final StateController<int> notifier = StateController<int>(10);
    final Signal<int> mirrored = signalFromStateNotifier<int>(notifier);

    mirrored.dispose();
    expect(() => notifier.state = 11, returnsNormally);

    notifier.dispose();
  });

  test('riverpod migration report keeps defaults and custom values', () {
    final VirexMigrationReport report = riverpodMigrationReport(
      feature: 'feed',
      notes: 'incremental rollout',
    );

    expect(report.sourceFramework, 'riverpod');
    expect(report.feature, 'feed');
    expect(report.estimatedDevDays, 1.5);
    expect(report.notes, 'incremental rollout');
  });
}
