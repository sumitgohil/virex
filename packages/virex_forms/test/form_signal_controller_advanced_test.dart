import 'package:test/test.dart';
import 'package:virex/virex_core.dart';
import 'package:virex_forms/virex_forms.dart';

void main() {
  setUp(debugResetVirexForTests);

  test('validateAll fills error map for all registered validators', () {
    final FormSignalController form = FormSignalController(
      initialValues: <String, String>{'email': 'bad', 'name': ''},
    );

    form.setValidator(
      'email',
      (String value) => value.contains('@') ? null : 'email_invalid',
    );
    form.setValidator(
      'name',
      (String value) => value.isEmpty ? 'name_required' : null,
    );

    final bool ok = form.validateAll();

    expect(ok, isFalse);
    expect(form.errors.value['email'], 'email_invalid');
    expect(form.errors.value['name'], 'name_required');
    expect(form.isValid.value, isFalse);

    form.dispose();
  });

  test('submit fails fast when form is invalid', () async {
    final FormSignalController form = FormSignalController();
    bool submitted = false;
    form.setValidator(
      'username',
      (String value) => value.isEmpty ? 'required' : null,
    );

    final bool ok = await form.submit((Map<String, String> values) async {
      submitted = true;
    });

    expect(ok, isFalse);
    expect(submitted, isFalse);
    expect(form.isSubmitting.value, isFalse);

    form.dispose();
  });

  test('isSubmitting resets when submit callback throws', () async {
    final FormSignalController form = FormSignalController(
      initialValues: <String, String>{'username': 'virex'},
    );
    form.setValidator(
      'username',
      (String value) => value.isEmpty ? 'required' : null,
    );

    await expectLater(
      form.submit((Map<String, String> values) async {
        throw StateError('save failed');
      }),
      throwsStateError,
    );

    expect(form.isSubmitting.value, isFalse);
    form.dispose();
  });

  test('setting validator validates existing field value immediately', () {
    final FormSignalController form = FormSignalController(
      initialValues: <String, String>{'email': 'bad-email'},
    );

    form.setValidator(
      'email',
      (String value) => value.contains('@') ? null : 'invalid',
    );
    expect(form.errors.value['email'], 'invalid');

    form.setField('email', 'team@virex.dev');
    expect(form.errors.value['email'], isNull);
    expect(form.isValid.value, isTrue);

    form.dispose();
  });
}
