import 'package:virex/virex.dart';

final class ProfileFeature {
  ProfileFeature();

  final Signal<String> name = signal<String>('Founder', name: 'profile_name');
  final Signal<String> bio = signal<String>(
    'Building with Virex',
    name: 'profile_bio',
  );

  late final Computed<bool> valid = computed<bool>(
    () => name.value.trim().length >= 2 && bio.value.trim().length >= 10,
    name: 'profile_valid',
  );

  Future<void> save() async {
    if (!valid.value) {
      throw StateError('Profile is invalid');
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  void dispose() {
    name.dispose();
    bio.dispose();
    valid.dispose();
  }
}
