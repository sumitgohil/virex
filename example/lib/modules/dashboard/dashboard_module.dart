import 'dart:async';

import 'package:flutter/material.dart';
import 'package:virex/virex.dart';

import '../../shared/rebuild_tracker.dart';

class DashboardModule extends StatefulWidget {
  const DashboardModule({super.key});

  @override
  State<DashboardModule> createState() => _DashboardModuleState();
}

final class _DashboardModuleState extends State<DashboardModule> {
  final Signal<int> _visits = signal<int>(0, name: 'dash_visits');
  final Signal<int> _orders = signal<int>(0, name: 'dash_orders');
  final Signal<int> _alerts = signal<int>(0, name: 'dash_alerts');

  late final Computed<int> _total = computed<int>(
    () => _visits.value + _orders.value + _alerts.value,
    name: 'dash_total',
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      batch(() {
        _visits.value += 2;
        _orders.value += 1;
        _alerts.value = (_alerts.value + 1) % 5;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _visits.dispose();
    _orders.dispose();
    _alerts.dispose();
    _total.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrackedRebuild(
      name: 'DashboardModule',
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _counterCard('Visits', _visits),
                  _counterCard('Orders', _orders),
                  _counterCard('Alerts', _alerts),
                  SignalBuilder(
                    builder: () => _tile('Total', _total.value.toString()),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _counterCard(String label, Signal<int> counter) {
    return SignalBuilder(builder: () => _tile(label, counter.value.toString()));
  }

  Widget _tile(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.shade100),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
