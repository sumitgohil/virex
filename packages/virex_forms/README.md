# virex_forms

Signal-first form controller for Virex.

`virex_forms` provides predictable form value, validation, and submission state as signals/computeds.

## Install

```bash
flutter pub add virex_forms
```

## Import

```dart
import 'package:virex_forms/virex_forms.dart';
```

## Usage

```dart
final form = FormSignalController(
  initialValues: {'email': '', 'password': ''},
);

form.setValidator('email', (value) {
  return value.contains('@') ? null : 'Invalid email';
});

form.setValidator('password', (value) {
  return value.length >= 8 ? null : 'Minimum 8 characters';
});

form.setField('email', 'team@virex.dev');
final ok = form.validateAll(); // bool
```

Submit:

```dart
final success = await form.submit((values) async {
  await api.login(values['email']!, values['password']!);
});
```

## Reactive State Exposed

- `values` (`Signal<Map<String, String>>`)
- `errors` (`Signal<Map<String, String?>>`)
- `isSubmitting` (`Signal<bool>`)
- `isValid` (`Computed<bool>`)

## API

- `setField(String field, String value)`
- `setValidator(String field, FieldValidator validator)`
- `validateField(String field)`
- `validateAll()`
- `submit(Future<void> Function(Map<String, String>) onSubmit)`
- `dispose()`

## Testing

```bash
cd packages/virex_forms
dart test
```

## Benchmarking Notes

For forms, the key metric is rebuild count under frequent field updates. Use your app’s widget tests and the core benchmark suite:

```bash
dart run benchmark/virex_benchmark.dart
```

## Related

- Core runtime: [`../../README.md`](../../README.md)
