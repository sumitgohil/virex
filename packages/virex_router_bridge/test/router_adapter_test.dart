import 'dart:async';

import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_router_bridge/virex_router_bridge.dart';

final class _FakeDriver implements RouterDriver {
  _FakeDriver(this._location);

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  String _location;

  @override
  String get location => _location;

  @override
  Stream<String> get onLocationChanged => _controller.stream;

  @override
  void go(String location) {
    _location = location;
  }

  void emit(String location) {
    _location = location;
    _controller.add(location);
  }
}

void main() {
  test('adapter syncs route changes both ways', () async {
    final _FakeDriver driver = _FakeDriver('/home');
    final RouterSignalAdapter adapter = RouterSignalAdapter(driver: driver);

    expect(adapter.route.value, '/home');

    driver.emit('/settings');
    await Future<void>.delayed(Duration.zero);
    expect(adapter.route.value, '/settings');

    adapter.route.value = '/about';
    VirexScheduler.instance.flush();
    expect(driver.location, '/about');

    adapter.dispose();
  });
}
