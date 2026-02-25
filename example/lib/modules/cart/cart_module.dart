import 'dart:math';

import 'package:flutter/material.dart';
import 'package:virex/virex.dart';

import '../../shared/rebuild_tracker.dart';

final class CartLine {
  const CartLine({required this.sku, required this.qty, required this.price});

  final String sku;
  final int qty;
  final double price;

  CartLine copyWith({int? qty, double? price}) {
    return CartLine(sku: sku, qty: qty ?? this.qty, price: price ?? this.price);
  }
}

class CartModule extends StatefulWidget {
  const CartModule({super.key});

  @override
  State<CartModule> createState() => _CartModuleState();
}

final class _CartModuleState extends State<CartModule> {
  final Signal<List<CartLine>> _lines = signal<List<CartLine>>(const <CartLine>[
    CartLine(sku: 'A100', qty: 2, price: 19.5),
    CartLine(sku: 'B200', qty: 1, price: 45),
    CartLine(sku: 'C300', qty: 4, price: 12.25),
  ], name: 'cart_lines');

  late final Computed<double> _subtotal = computed<double>(() {
    return _lines.value.fold<double>(0, (double sum, CartLine line) {
      return sum + line.qty * line.price;
    });
  }, name: 'cart_subtotal');

  late final AsyncSignal<double> _validator = asyncSignal<double>(
    () async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final double multiplier = 0.95 + Random().nextDouble() * 0.1;
      return _subtotal.value * multiplier;
    },
    autoStart: false,
    name: 'cart_validator',
  );

  @override
  void dispose() {
    _lines.dispose();
    _subtotal.dispose();
    _validator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrackedRebuild(
      name: 'CartModule',
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Shopping Cart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SignalBuilder(
                  builder: () => ListView(
                    children: _lines.value
                        .map((CartLine line) {
                          return ListTile(
                            title: Text(line.sku),
                            subtitle: Text(
                              '\$${line.price.toStringAsFixed(2)} each',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  onPressed: () =>
                                      _updateQty(line.sku, line.qty - 1),
                                  icon: const Icon(Icons.remove),
                                ),
                                Text('${line.qty}'),
                                IconButton(
                                  onPressed: () =>
                                      _updateQty(line.sku, line.qty + 1),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SignalBuilder(
                builder: () =>
                    Text('Subtotal: \$${_subtotal.value.toStringAsFixed(2)}'),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _validator.refresh,
                    child: const Text('Validate prices'),
                  ),
                  const SizedBox(width: 8),
                  SignalBuilder(
                    builder: () {
                      final AsyncState<double> state = _validator.value;
                      if (state.isLoading) {
                        return const Text('Validating...');
                      }
                      if (state.data != null) {
                        return Text(
                          'Validated total: \$${state.data!.toStringAsFixed(2)}',
                        );
                      }
                      if (state.error != null) {
                        return Text('Validation failed: ${state.error}');
                      }
                      return const Text('No validation yet');
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateQty(String sku, int qty) {
    final int safeQty = qty < 1 ? 1 : qty;
    _lines.value = _lines.value
        .map((CartLine line) {
          if (line.sku != sku) {
            return line;
          }
          return line.copyWith(qty: safeQty);
        })
        .toList(growable: false);
  }
}
