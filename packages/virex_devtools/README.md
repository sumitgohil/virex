# virex_devtools

Flutter DevTools panel widgets for Virex inspector data.

Use this package to embed runtime graph visibility directly in your app during development.

## Install

```bash
flutter pub add virex_devtools
```

## Import

```dart
import 'package:virex_devtools/virex_devtools.dart';
```

## Usage

```dart
MaterialApp(
  home: Scaffold(
    body: Column(
      children: const [
        Expanded(child: AppContent()),
        VirexDevtoolsPanel(
          autoSnapshots: true,
          maxRows: 10,
        ),
      ],
    ),
  ),
);
```

## What It Shows

- current flush epoch
- scheduler phase
- node counts (signals/computeds/effects)
- invariant status
- top node rows with dependency/subscriber counts

## API

- `class VirexDevtoolsPanel extends StatefulWidget`
  - `autoSnapshots` (`bool`, default `true`)
  - `maxRows` (`int`, default `8`)

## Operational Notes

- `autoSnapshots` toggles inspector auto-snapshot behavior while mounted.
- intended for debug/development workflows.

## Testing

```bash
cd packages/virex_devtools
flutter test
```

Analyze:

```bash
cd packages/virex_devtools
flutter analyze
```

## Benchmarking Notes

Track app frame time with and without panel enabled. For runtime baseline, use core benchmarks:

```bash
dart run benchmark/virex_benchmark.dart
```

## Related

- Core runtime: [`../../README.md`](../../README.md)
