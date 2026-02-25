import 'package:virex/virex_core.dart';

typedef FieldValidator = String? Function(String value);

/// Signal-first controller for form value, validation, and submission lifecycle.
final class FormSignalController {
  FormSignalController({
    Map<String, String> initialValues = const <String, String>{},
  }) : values = signal<Map<String, String>>(
         Map<String, String>.from(initialValues),
         name: 'form_values',
       ),
       errors = signal<Map<String, String?>>(
         <String, String?>{},
         name: 'form_errors',
       ),
       isSubmitting = signal<bool>(false, name: 'form_submitting'),
       _validators = <String, FieldValidator>{} {
    isValid = computed<bool>(() {
      final Map<String, String?> current = errors.value;
      for (final String? message in current.values) {
        if (message != null) {
          return false;
        }
      }
      return true;
    }, name: 'form_is_valid');
  }

  final Signal<Map<String, String>> values;
  final Signal<Map<String, String?>> errors;
  final Signal<bool> isSubmitting;
  final Map<String, FieldValidator> _validators;
  late final Computed<bool> isValid;

  void setField(String field, String value) {
    final Map<String, String> next = Map<String, String>.from(values.value);
    next[field] = value;
    values.value = next;
    validateField(field);
  }

  void setValidator(String field, FieldValidator validator) {
    _validators[field] = validator;
    validateField(field);
  }

  String? validateField(String field) {
    final FieldValidator? validator = _validators[field];
    final String currentValue = values.value[field] ?? '';
    final String? message = validator?.call(currentValue);

    final Map<String, String?> nextErrors = Map<String, String?>.from(
      errors.value,
    );
    nextErrors[field] = message;
    errors.value = nextErrors;

    return message;
  }

  bool validateAll() {
    bool ok = true;
    final Map<String, String?> nextErrors = Map<String, String?>.from(
      errors.value,
    );

    for (final MapEntry<String, FieldValidator> entry in _validators.entries) {
      final String currentValue = values.value[entry.key] ?? '';
      final String? message = entry.value(currentValue);
      nextErrors[entry.key] = message;
      if (message != null) {
        ok = false;
      }
    }

    errors.value = nextErrors;
    return ok;
  }

  Future<bool> submit(
    Future<void> Function(Map<String, String> values) onSubmit,
  ) async {
    if (!validateAll()) {
      return false;
    }

    isSubmitting.value = true;
    try {
      await onSubmit(values.value);
      return true;
    } finally {
      isSubmitting.value = false;
    }
  }

  void dispose() {
    values.dispose();
    errors.dispose();
    isSubmitting.dispose();
    isValid.dispose();
  }
}
