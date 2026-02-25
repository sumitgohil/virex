import 'dart:async';

import 'package:virex/virex_core.dart';

/// Minimal driver abstraction to integrate app routers with Virex.
abstract interface class RouterDriver {
  String get location;

  Stream<String> get onLocationChanged;

  void go(String location);
}

/// Synchronizes router location with a signal state.
final class RouterSignalAdapter {
  RouterSignalAdapter({
    required RouterDriver driver,
    String signalName = 'route',
  }) : _driver = driver,
       route = signal<String>(driver.location, name: signalName) {
    _driverSub = _driver.onLocationChanged.listen((String location) {
      if (!route.disposed) {
        route.value = location;
      }
    });

    _routeEffect = effect(() {
      final String next = route.value;
      if (next != _driver.location) {
        _driver.go(next);
      }
    });
  }

  final RouterDriver _driver;
  final Signal<String> route;

  late final StreamSubscription<String> _driverSub;
  late final EffectHandle _routeEffect;

  void dispose() {
    _driverSub.cancel();
    _routeEffect.dispose();
    route.dispose();
  }
}
