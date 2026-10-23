import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device owner's local profile. There is no account backend; this is
/// stored on the device only.
class UserProfile {
  final String name;
  final String email;

  const UserProfile({this.name = '', this.email = ''});

  bool get isEmpty => name.trim().isEmpty;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  static const _nameKey = 'profile_name';
  static const _emailKey = 'profile_email';

  @override
  Future<UserProfile> build() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      name: prefs.getString(_nameKey) ?? '',
      email: prefs.getString(_emailKey) ?? '',
    );
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, profile.name.trim());
    await prefs.setString(_emailKey, profile.email.trim());
    state = AsyncData(
      UserProfile(name: profile.name.trim(), email: profile.email.trim()),
    );
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);
