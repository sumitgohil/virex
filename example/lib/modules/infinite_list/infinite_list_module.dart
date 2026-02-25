import 'dart:math';

import 'package:flutter/material.dart';
import 'package:virex/virex.dart';

import '../../shared/rebuild_tracker.dart';

class InfiniteListModule extends StatefulWidget {
  const InfiniteListModule({super.key});

  @override
  State<InfiniteListModule> createState() => _InfiniteListModuleState();
}

final class _InfiniteListModuleState extends State<InfiniteListModule> {
  final Signal<int> _page = signal<int>(0, name: 'infinite_page');
  final Signal<List<String>> _items = signal<List<String>>(
    <String>[],
    name: 'infinite_items',
  );

  late final AsyncSignal<List<String>> _fetchPage = asyncSignal<List<String>>(
    () async {
      await Future<void>.delayed(
        Duration(milliseconds: 300 + Random().nextInt(400)),
      );
      final int page = _page.value;
      return List<String>.generate(
        20,
        (int index) => 'Item ${page * 20 + index}',
      );
    },
    autoStart: true,
    name: 'infinite_fetch',
  );

  late final EffectHandle _appendEffect = effect(() {
    final AsyncState<List<String>> state = _fetchPage.value;
    if (state.data == null || state.isLoading) {
      return;
    }
    final Set<String> merged = <String>{..._items.value, ...state.data!};
    _items.value = merged.toList(growable: false);
  });

  @override
  void dispose() {
    _appendEffect.dispose();
    _page.dispose();
    _items.dispose();
    _fetchPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrackedRebuild(
      name: 'InfiniteListModule',
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  FilledButton(
                    onPressed: _loadMore,
                    child: const Text('Load next page'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _refresh,
                    child: const Text('Refresh from page 0'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SignalBuilder(
                builder: () {
                  final AsyncState<List<String>> state = _fetchPage.value;
                  if (state.isLoading) {
                    return const Text('Fetching page...');
                  }
                  if (state.error != null) {
                    return Text('Fetch error: ${state.error}');
                  }
                  return Text('Loaded page: ${_page.value}');
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SignalBuilder(
                  builder: () => ListView.builder(
                    itemCount: _items.value.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(title: Text(_items.value[index]));
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadMore() async {
    _page.value = _page.value + 1;
    await _fetchPage.refresh();
  }

  Future<void> _refresh() async {
    _page.value = 0;
    _items.value = <String>[];
    await _fetchPage.refresh();
  }
}
