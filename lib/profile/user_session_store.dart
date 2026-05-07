import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cached display name + avatar URL for the signed-in user (written at login, merged after profile edits).
abstract final class UserSessionStore {
  static const _uidKey = 'user_session_uid';
  static const _nameKey = 'user_session_display_name';
  static const _photoKey = 'user_session_photo_url';

  /// Bumped when session cache changes or after pull-to-refresh so UI (e.g. home greeting) refetches profile.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void bumpRevision() => revision.value++;

  static Future<void> persistFromFirebaseUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uidKey, user.uid);
    final dn = user.displayName?.trim();
    final emailLocal = user.email?.split('@').first.trim();
    final name = (dn != null && dn.isNotEmpty)
        ? dn
        : (emailLocal != null && emailLocal.isNotEmpty)
            ? emailLocal
            : 'Traveler';
    await prefs.setString(_nameKey, name);
    await prefs.setString(_photoKey, user.photoURL ?? '');
    bumpRevision();
  }

  static Future<void> mergeFromProfile({
    required String uid,
    required String fullName,
    required String photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uidKey, uid);
    if (fullName.trim().isNotEmpty) {
      await prefs.setString(_nameKey, fullName.trim());
    }
    if (photoUrl.trim().isNotEmpty) {
      await prefs.setString(_photoKey, photoUrl.trim());
    }
    bumpRevision();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uidKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_photoKey);
    bumpRevision();
  }

  static Future<UserSessionSnapshot?> readForUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_uidKey) != uid) return null;
    return UserSessionSnapshot(
      displayName: prefs.getString(_nameKey) ?? '',
      photoUrl: prefs.getString(_photoKey) ?? '',
    );
  }
}

class UserSessionSnapshot {
  const UserSessionSnapshot({required this.displayName, required this.photoUrl});

  final String displayName;
  final String photoUrl;
}
