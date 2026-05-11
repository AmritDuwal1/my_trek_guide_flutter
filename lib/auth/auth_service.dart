import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tour_mobile/auth/guest_mode_store.dart';
import 'package:tour_mobile/profile/profile_service.dart';
import 'package:tour_mobile/config/api_config.dart';
import 'package:tour_mobile/profile/user_session_store.dart';
import 'package:tour_mobile/services/logging_http_client.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, http.Client? apiClient})
      : _auth = auth ?? FirebaseAuth.instance,
        _apiClient = apiClient ?? LoggingHttpClient();

  final FirebaseAuth _auth;
  final http.Client _apiClient;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Verifies the Firebase session with the backend (`GET /me/`) so profile and other
  /// authenticated API routes work. Sends [X-Dev-Uid] for DEBUG-only server fallback.
  Future<void> linkSessionWithApi() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception('Could not obtain ID token for API');
    }
    if (kDebugMode) {
      debugPrint('[AUTH] linkSessionWithApi uid=${user.uid}');
      debugPrint('[AUTH] apiBaseUrl=${apiBaseUrl()} isLive=$isLive');
      debugPrint('[AUTH] idToken length=${token.length} prefix=${token.substring(0, token.length < 12 ? token.length : 12)}');
    }
    final res = await _apiClient.get(
      Uri.parse('${apiBaseUrl()}/me/'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Dev-Uid': user.uid,
      },
    );
    if (res.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('[AUTH] /me/ failed status=${res.statusCode} body=${res.body}');
      }
      throw Exception('Could not link session with API (${res.statusCode})');
    }
    // Successful API link: disable guest mode.
    await GuestModeStore.setEnabled(false);
    final linked = _auth.currentUser;
    if (linked != null) {
      await UserSessionStore.persistFromFirebaseUser(linked);
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await linkSessionWithApi();
      return cred;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH] signUpWithEmail failed code=${e.code} message=${e.message}');
      }
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await linkSessionWithApi();
      return cred;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH] signInWithEmail failed code=${e.code} message=${e.message}');
      }
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final oauthCred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(oauthCred);
    await linkSessionWithApi();
    return userCred;
  }

  /// Android/web: Firebase opens the OAuth flow against `__/auth/handler` correctly.
  /// iOS/macOS: native `sign_in_with_apple` (do not use Firebase handler as
  /// `sign_in_with_apple`’s [WebAuthenticationOptions.redirectUri] — that page
  /// expects Firebase JS sessionStorage and shows "missing initial state").
  bool get _useFirebaseAppleOAuth =>
      defaultTargetPlatform == TargetPlatform.android || kIsWeb;

  Future<AuthorizationCredentialAppleID> _appleIdCredentialNative() async {
    return SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
  }

  Future<UserCredential> signInWithApple() async {
    if (_useFirebaseAppleOAuth) {
      final apple = AppleAuthProvider();
      apple.addScope('email');
      apple.addScope('name');
      final cred = await _auth.signInWithProvider(apple);
      await linkSessionWithApi();
      return cred;
    }
    final result = await _appleIdCredentialNative();
    final oauthCred = OAuthProvider('apple.com').credential(
      idToken: result.identityToken,
      accessToken: result.authorizationCode,
    );
    final userCred = await _auth.signInWithCredential(oauthCred);
    await linkSessionWithApi();
    return userCred;
  }

  Future<void> signOut() async {
    await UserSessionStore.clear();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }

    // 1) Delete app data (API profile + favorites, plus profile photo in Storage).
    final profile = ProfileService();
    try {
      await profile.deleteMyProfile();
    } catch (_) {
      // Best-effort: continue so user can still delete their auth account.
    }
    try {
      await profile.deleteProfilePhoto();
    } catch (_) {
      // ignore
    }

    // 2) Delete Firebase Auth user (may require recent login).
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _reauthenticate(user);
        await user.delete();
      } else {
        rethrow;
      }
    }

    await UserSessionStore.clear();
  }

  Future<void> _reauthenticate(User user) async {
    final providers = user.providerData.map((p) => p.providerId).toSet();

    if (providers.contains('google.com')) {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('Google re-auth cancelled');
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(cred);
      return;
    }

    if (providers.contains('apple.com')) {
      if (_useFirebaseAppleOAuth) {
        final apple = AppleAuthProvider();
        apple.addScope('email');
        apple.addScope('name');
        await user.reauthenticateWithProvider(apple);
        return;
      }
      final result = await _appleIdCredentialNative();
      final cred = OAuthProvider('apple.com').credential(
        idToken: result.identityToken,
        accessToken: result.authorizationCode,
      );
      await user.reauthenticateWithCredential(cred);
      return;
    }

    if (providers.contains('password')) {
      throw Exception('Please sign in again (email/password) then retry deleting the account.');
    }

    throw Exception('Please sign in again then retry deleting the account.');
  }
}

