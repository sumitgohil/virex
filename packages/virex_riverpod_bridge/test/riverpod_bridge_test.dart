import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_riverpod_bridge/virex_riverpod_bridge.dart';

void main() {
  test('riverpod provider mirrors signal updates', () {
    final Signal<int> counter = signal<int>(0);
    final provider = riverpodSignalProvider<int>(counter);
    final container = ProviderContainer();

    expect(container.read(provider), 0);

    counter.value = 3;
    VirexScheduler.instance.flush();

    expect(container.read(provider), 3);

    container.dispose();
    counter.dispose();
  });

  test('signalFromStateNotifier mirrors notifier updates', () {
    final StateController<int> notifier = StateController<int>(1);
    final Signal<int> mirrored = signalFromStateNotifier<int>(notifier);

    notifier.state = 9;
    expect(mirrored.value, 9);

    mirrored.dispose();
    notifier.dispose();
  });
}
