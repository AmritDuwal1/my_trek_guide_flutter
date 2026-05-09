import 'dart:io';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tour_mobile/config/api_config.dart';
import 'package:tour_mobile/services/logging_http_client.dart';
import 'package:tour_mobile/profile/user_profile.dart';

class ProfileService {
  ProfileService({
    http.Client? client,
  })  : _client = client ?? LoggingHttpClient(),
        _clientRaw = http.Client();

  final http.Client _client;
  final http.Client _clientRaw;

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

  Future<void> deleteMyProfile() async {
    final res = await _client.delete(
      _uri('/profile/'),
      headers: {
        ...await _authHeaders(),
      },
    );
    if (res.statusCode == 401) {
      throw Exception('Unauthorized (sign in again)');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to delete profile (${res.statusCode})');
    }
  }

  Future<void> deleteProfilePhoto() async {
    final res = await _client.delete(
      _uri('/profile/photo/'),
      headers: {
        ...await _authHeaders(),
      },
    );
    if (res.statusCode == 401) {
      throw Exception('Unauthorized (sign in again)');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to delete photo (${res.statusCode})');
    }
  }

  Future<String> uploadProfilePhoto({
    required File file,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/profile/photo/'))
      ..headers.addAll(await _authHeaders())
      ..files.add(await http.MultipartFile.fromPath('photo', file.path));

    final streamed = await _clientRaw.send(req);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 401) {
      throw Exception('Unauthorized (sign in again)');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to upload photo (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['photoUrl'] as String?) ?? '';
  }
}

