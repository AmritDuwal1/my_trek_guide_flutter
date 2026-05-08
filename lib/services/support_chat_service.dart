import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tour_mobile/config/api_config.dart';
import 'package:tour_mobile/services/logging_http_client.dart';

class SupportChatMessage {
  final int id;
  final int threadId;
  final String sender; // user | support
  final String text;
  final int createdAtMs;

  const SupportChatMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.text,
    required this.createdAtMs,
  });

  factory SupportChatMessage.fromJson(Map<String, dynamic> json) {
    return SupportChatMessage(
      id: (json['id'] as num).toInt(),
      threadId: (json['threadId'] as num).toInt(),
      sender: (json['sender'] as String?) ?? 'user',
      text: (json['text'] as String?) ?? '',
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class SupportChatService {
  SupportChatService({http.Client? client}) : _client = client ?? LoggingHttpClient();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? q]) => Uri.parse('${apiBaseUrl()}$path').replace(queryParameters: q);

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

  Future<int> getOrCreateThreadId() async {
    final res = await _client.get(_uri('/support/chat/thread/'), headers: await _authHeaders());
    if (res.statusCode == 401) throw Exception('Unauthorized (sign in again)');
    if (res.statusCode != 200) throw Exception('Failed to load chat (${res.statusCode})');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final thread = json['thread'] as Map<String, dynamic>;
    return (thread['id'] as num).toInt();
  }

  Future<List<SupportChatMessage>> listMessages({int? sinceMs}) async {
    final q = <String, String>{};
    if (sinceMs != null) q['since_ms'] = sinceMs.toString();
    final res = await _client.get(_uri('/support/chat/messages/', q.isEmpty ? null : q), headers: await _authHeaders());
    if (res.statusCode == 401) throw Exception('Unauthorized (sign in again)');
    if (res.statusCode != 200) throw Exception('Failed to load messages (${res.statusCode})');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (json['messages'] as List<dynamic>? ?? const []);
    return list.whereType<Map<String, dynamic>>().map(SupportChatMessage.fromJson).toList(growable: false);
  }

  Future<SupportChatMessage> sendMessage(String text) async {
    final res = await _client.post(
      _uri('/support/chat/messages/'),
      headers: {
        'Content-Type': 'application/json',
        ...await _authHeaders(),
      },
      body: jsonEncode({'text': text.trim()}),
    );
    if (res.statusCode == 401) throw Exception('Unauthorized (sign in again)');
    if (res.statusCode != 200) throw Exception('Failed to send (${res.statusCode})');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return SupportChatMessage.fromJson(json['message'] as Map<String, dynamic>);
  }
}

