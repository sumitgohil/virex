import 'package:virex/virex.dart';

final class TodosFeature {
  TodosFeature();

  final Signal<List<String>> items = signal<List<String>>(
    <String>[],
    name: 'todos_items',
  );
  final Signal<String> query = signal<String>('', name: 'todos_query');

  late final Computed<List<String>> filtered = computed<List<String>>(() {
    final String q = query.value.toLowerCase();
    return items.value
        .where((String item) => item.toLowerCase().contains(q))
        .toList();
  }, name: 'todos_filtered');

  void add(String item) {
    items.value = <String>[...items.value, item];
  }

  void dispose() {
    items.dispose();
    query.dispose();
    filtered.dispose();
  }
}
