import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Could not obtain ID token for API');
    }
    final res = await _apiClient.get(
      Uri.parse('${apiBaseUrl()}/me/'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Dev-Uid': user.uid,
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Could not link session with API (${res.statusCode})');
    }
    final linked = _auth.currentUser;
    if (linked != null) {
      await UserSessionStore.persistFromFirebaseUser(linked);
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await linkSessionWithApi();
    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await linkSessionWithApi();
    return cred;
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

  Future<UserCredential> signInWithApple() async {
    final result = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
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
}

