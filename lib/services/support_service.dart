import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tour_mobile/config/api_config.dart';
import 'package:tour_mobile/services/logging_http_client.dart';

class SupportService {
  SupportService({http.Client? client}) : _client = client ?? LoggingHttpClient();

  final http.Client _client;

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
      headers['X-Dev-Uid'] = uid;
    }
    return headers;
  }

  Future<void> submitComplaint({
    required String email,
    required String phone,
    required String subject,
    required String message,
  }) async {
    final res = await _client.post(
      _uri('/support/complaints/'),
      headers: {
        'Content-Type': 'application/json',
        ...await _authHeaders(),
      },
      body: jsonEncode({
        'email': email.trim(),
        'phone': phone.trim(),
        'subject': subject.trim(),
        'message': message.trim(),
      }),
    );
    if (res.statusCode == 401) {
      throw Exception('Unauthorized (sign in again)');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to send (${res.statusCode})');
    }
  }
}

