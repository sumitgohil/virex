import 'dart:math';

import 'package:flutter/material.dart';
import 'package:virex/virex.dart';
import 'package:virex_forms/virex_forms.dart';

import '../../shared/rebuild_tracker.dart';

class ProfileModule extends StatefulWidget {
  const ProfileModule({super.key});

  @override
  State<ProfileModule> createState() => _ProfileModuleState();
}

final class _ProfileModuleState extends State<ProfileModule> {
  late final FormSignalController _form = FormSignalController(
    initialValues: <String, String>{
      'name': 'Alex Engineer',
      'bio': 'I build reactive systems.',
    },
  );
  final Signal<String?> _saveError = signal<String?>(null, name: 'profile_err');
  final Signal<String?> _saveSuccess = signal<String?>(
    null,
    name: 'profile_success',
  );

  @override
  void initState() {
    super.initState();
    _form.setValidator('name', (String value) {
      return value.trim().length >= 3 ? null : 'Name must be at least 3 chars';
    });
    _form.setValidator('bio', (String value) {
      return value.trim().length >= 10 ? null : 'Bio must be at least 10 chars';
    });
  }

  @override
  void dispose() {
    _form.dispose();
    _saveError.dispose();
    _saveSuccess.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrackedRebuild(
      name: 'ProfileModule',
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              SignalBuilder(
                builder: () => TextFormField(
                  initialValue: _form.values.value['name'],
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (String value) => _form.setField('name', value),
                ),
              ),
              const SizedBox(height: 8),
              SignalBuilder(
                builder: () => TextFormField(
                  initialValue: _form.values.value['bio'],
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  onChanged: (String value) => _form.setField('bio', value),
                ),
              ),
              const SizedBox(height: 8),
              SignalBuilder(
                builder: () => Row(
                  children: <Widget>[
                    Icon(
                      _form.isValid.value ? Icons.check_circle : Icons.error,
                      color: _form.isValid.value ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(_form.isValid.value ? 'Form valid' : 'Form invalid'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SignalBuilder(
                builder: () => FilledButton(
                  onPressed: _form.isSubmitting.value ? null : _saveProfile,
                  child: Text(
                    _form.isSubmitting.value ? 'Saving...' : 'Save profile',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SignalBuilder(
                builder: () {
                  final String? error = _saveError.value;
                  if (error != null) {
                    return Text('Save failed: $error');
                  }
                  final String? success = _saveSuccess.value;
                  if (success != null) {
                    return Text(success);
                  }
                  return const Text('No save yet');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    _saveError.value = null;
    try {
      final bool saved = await _form.submit((Map<String, String> values) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (Random().nextInt(5) == 0) {
          throw StateError('Simulated network failure');
        }
        if ((values['bio'] ?? '').contains('forbidden')) {
          throw StateError('Bio contains blocked word');
        }
      });

      if (saved) {
        _saveSuccess.value = 'Saved at ${DateTime.now()}';
      } else {
        _saveSuccess.value = null;
      }
    } catch (error) {
      _saveSuccess.value = null;
      _saveError.value = '$error';
    }
  }
}
