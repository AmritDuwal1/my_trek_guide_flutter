import 'dart:io';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tour_mobile/config/api_config.dart';
import 'package:tour_mobile/services/logging_http_client.dart';
import 'package:tour_mobile/profile/user_profile.dart';

class ProfileService {
  ProfileService({
    http.Client? client,
    FirebaseStorage? storage,
  })  : _client = client ?? LoggingHttpClient(),
        _storage = storage ?? FirebaseStorage.instance;

  final http.Client _client;
  final FirebaseStorage _storage;

  Uri _uri(String path) => Uri.parse('${apiBaseUrl()}$path');

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final uid = user?.uid;
    if (uid != null && uid.isNotEmpty) {
      // Matches `/me/` + Django `_require_uid` DEBUG fallback when Firebase Admin is not configured.
      headers['X-Dev-Uid'] = uid;
    }
    return headers;
  }

  Future<UserProfile?> get(String uid) async {
    // UID comes from FirebaseAuth; the API resolves the current user from token.
    final res = await _client.get(_uri('/profile/'), headers: await _authHeaders());
    if (res.statusCode == 404) return null;
    if (res.statusCode == 401) {
      throw Exception('Unauthorized (sign in again)');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to load profile (${res.statusCode})');
    }
    return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> upsert(UserProfile profile) async {
    final res = await _client.put(
      _uri('/profile/'),
      headers: {
        'Content-Type': 'application/json',
        ...await _authHeaders(),
      },
      body: jsonEncode(profile.toJson()),
    );
    if (res.statusCode == 401) {
      throw Exception('Unauthorized (sign in again)');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to save profile (${res.statusCode})');
    }
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref('users/$uid/profile.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}

