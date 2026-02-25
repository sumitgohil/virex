# Contributing to Virex

## Prerequisites
- Flutter 3.38.2
- Dart 3.10.0

## Setup

```bash
flutter pub get
cd example && flutter pub get
```

## Local quality gates

```bash
flutter analyze
flutter test
dart run benchmark/virex_benchmark.dart
```

Coverage gate target is enforced in CI (`>= 70%`).

## Branch and PR guidelines
- Keep changes focused and atomic.
- Add or update tests for behavioral changes.
- Include benchmark notes for runtime-sensitive changes.
- Update docs when public behavior changes.

## Commit style
Use clear imperative commit messages, for example:
- `scheduler: enforce epoch enqueue dedupe`
- `inspector: add service extension snapshot endpoint`

## Reporting bugs
Use the bug report template and include:
- Flutter and Dart versions
- Minimal reproduction
- Expected vs actual behavior
- Logs or stack traces
