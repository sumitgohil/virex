import 'package:flutter/material.dart';
import 'package:virex/virex.dart';

import '../../shared/rebuild_tracker.dart';

final class TodoItem {
  const TodoItem({required this.id, required this.title, required this.done});

  final int id;
  final String title;
  final bool done;

  TodoItem copyWith({String? title, bool? done}) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      done: done ?? this.done,
    );
  }
}

class TodosModule extends StatefulWidget {
  const TodosModule({super.key});

  @override
  State<TodosModule> createState() => _TodosModuleState();
}

final class _TodosModuleState extends State<TodosModule> {
  final Signal<List<TodoItem>> _todos = signal<List<TodoItem>>(
    List<TodoItem>.generate(
      500,
      (int index) =>
          TodoItem(id: index, title: 'Task #$index', done: index.isEven),
    ),
    name: 'todos_list',
  );

  final Signal<String> _query = signal<String>('', name: 'todos_query');
  final Signal<bool> _showDoneOnly = signal<bool>(
    false,
    name: 'todos_done_only',
  );

  late final Computed<List<TodoItem>> _filtered = computed<List<TodoItem>>(() {
    final String q = _query.value.toLowerCase();
    final bool doneOnly = _showDoneOnly.value;

    final List<TodoItem> next =
        _todos.value
            .where((TodoItem item) {
              if (doneOnly && !item.done) {
                return false;
              }
              return item.title.toLowerCase().contains(q);
            })
            .toList(growable: false)
          ..sort((TodoItem a, TodoItem b) => a.title.compareTo(b.title));

    return next;
  }, name: 'todos_filtered');

  @override
  void dispose() {
    _todos.dispose();
    _query.dispose();
    _showDoneOnly.dispose();
    _filtered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrackedRebuild(
      name: 'TodosModule',
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      onChanged: (String value) => _query.value = value,
                      decoration: const InputDecoration(
                        hintText: 'Search todos...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SignalBuilder(
                    builder: () => FilterChip(
                      selected: _showDoneOnly.value,
                      label: const Text('Done only'),
                      onSelected: (bool value) => _showDoneOnly.value = value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  FilledButton(
                    onPressed: _bulkToggle,
                    child: const Text('Bulk toggle first 50'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _addTodo,
                    child: const Text('Add todo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SignalBuilder(
                  builder: () {
                    final List<TodoItem> items = _filtered.value;
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final TodoItem item = items[index];
                        return CheckboxListTile(
                          value: item.done,
                          title: Text(item.title),
                          onChanged: (_) => _toggle(item.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggle(int id) {
    _todos.value = _todos.value
        .map(
          (TodoItem item) =>
              item.id == id ? item.copyWith(done: !item.done) : item,
        )
        .toList(growable: false);
  }

  void _bulkToggle() {
    _todos.value = _todos.value
        .map(
          (TodoItem item) =>
              item.id < 50 ? item.copyWith(done: !item.done) : item,
        )
        .toList(growable: false);
  }

  void _addTodo() {
    final List<TodoItem> current = _todos.value;
    final int nextId = current.isEmpty ? 0 : current.last.id + 1;
    _todos.value = <TodoItem>[
      ...current,
      TodoItem(id: nextId, title: 'Task #$nextId', done: false),
    ];
  }
}
