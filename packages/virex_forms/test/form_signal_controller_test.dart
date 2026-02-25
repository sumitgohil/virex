import 'package:test/test.dart';
import 'package:virex_forms/virex_forms.dart';

void main() {
  test('validates fields and tracks validity', () {
    final FormSignalController form = FormSignalController();

    form.setValidator('email', (String value) {
      return value.contains('@') ? null : 'invalid';
    });

    form.setField('email', 'bad');
    expect(form.isValid.value, isFalse);

    form.setField('email', 'dev@virex.dev');
    expect(form.isValid.value, isTrue);

    form.dispose();
  });

  test('submit only runs when valid', () async {
    final FormSignalController form = FormSignalController(
      initialValues: <String, String>{'name': 'virex'},
    );

    bool submitted = false;
    form.setValidator(
      'name',
      (String value) => value.isEmpty ? 'required' : null,
    );

    final bool ok = await form.submit((Map<String, String> values) async {
      submitted = true;
    });

    expect(ok, isTrue);
    expect(submitted, isTrue);

    form.dispose();
  });
}
