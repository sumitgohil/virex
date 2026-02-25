import 'dart:async';

import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_router_bridge/virex_router_bridge.dart';

final class _CountingDriver implements RouterDriver {
  _CountingDriver(this._location);

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  String _location;
  int goCalls = 0;

  @override
  String get location => _location;

  @override
  Stream<String> get onLocationChanged => _controller.stream;

  @override
  void go(String location) {
    goCalls += 1;
    _location = location;
  }

  void emit(String location) {
    _location = location;
    _controller.add(location);
  }

  Future<void> close() => _controller.close();
}

void main() {
  setUp(debugResetVirexForTests);

  test('adapter avoids redundant driver.go calls for equal route values', () {
    final _CountingDriver driver = _CountingDriver('/home');
    final RouterSignalAdapter adapter = RouterSignalAdapter(driver: driver);

    adapter.route.value = '/home';
    VirexScheduler.instance.flush();
    expect(driver.goCalls, 0);

    adapter.route.value = '/settings';
    VirexScheduler.instance.flush();
    expect(driver.goCalls, 1);

    adapter.route.value = '/settings';
    VirexScheduler.instance.flush();
    expect(driver.goCalls, 1);

    adapter.dispose();
    driver.close();
  });

  test(
    'driver stream updates are ignored safely after adapter dispose',
    () async {
      final _CountingDriver driver = _CountingDriver('/start');
      final RouterSignalAdapter adapter = RouterSignalAdapter(driver: driver);

      adapter.dispose();
      expect(() => driver.emit('/after-dispose'), returnsNormally);
      await Future<void>.delayed(Duration.zero);

      expect(adapter.route.disposed, isTrue);
      await driver.close();
    },
  );

  test('route and driver stay in sync across rapid change bursts', () async {
    final _CountingDriver driver = _CountingDriver('/a');
    final RouterSignalAdapter adapter = RouterSignalAdapter(driver: driver);

    driver.emit('/b');
    driver.emit('/c');
    await Future<void>.delayed(Duration.zero);
    expect(adapter.route.value, '/c');

    adapter.route.value = '/d';
    adapter.route.value = '/e';
    VirexScheduler.instance.flush();
    expect(driver.location, '/e');

    adapter.dispose();
    await driver.close();
  });
}
