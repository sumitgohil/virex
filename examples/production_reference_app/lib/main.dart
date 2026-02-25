import 'package:flutter/material.dart';

import 'app/app_shell.dart';

void main() {
  runApp(const ProductionReferenceApp());
}

class ProductionReferenceApp extends StatelessWidget {
  const ProductionReferenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Virex Reference',
      theme: ThemeData(useMaterial3: true),
      home: const AppShell(),
    );
  }
}
