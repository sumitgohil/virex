import 'dart:async';

import 'package:virex/virex.dart';

final class DashboardFeature {
  DashboardFeature() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      visits.value = visits.value + 1;
    });
  }

  final Signal<int> visits = signal<int>(0, name: 'dashboard_visits');
  late final Computed<String> summary = computed<String>(
    () => 'Visits today: ${visits.value}',
    name: 'dashboard_summary',
  );

  Timer? _timer;

  void dispose() {
    _timer?.cancel();
    visits.dispose();
    summary.dispose();
  }
}
