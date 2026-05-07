import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tour_mobile/config/api_config.dart';
import 'package:tour_mobile/models/itinerary.dart';
import 'package:tour_mobile/services/logging_http_client.dart';

class FavoritesService {
  FavoritesService({http.Client? client}) : _client = client ?? LoggingHttpClient();

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

  Future<bool> isFavorite(String itineraryId) async {
    final res = await _client.get(_uri('/favorites/$itineraryId/'), headers: await _authHeaders());
    if (res.statusCode == 401) throw Exception('Unauthorized');
    if (res.statusCode != 200) throw Exception('Failed (${res.statusCode})');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['favorite'] as bool?) ?? false;
  }

  Future<bool> setFavorite(String itineraryId, bool favorite) async {
    final headers = await _authHeaders();
    late http.Response res;
    if (favorite) {
      res = await _client.put(_uri('/favorites/$itineraryId/'), headers: headers);
    } else {
      res = await _client.delete(_uri('/favorites/$itineraryId/'), headers: headers);
    }
    if (res.statusCode == 401) throw Exception('Unauthorized');
    if (res.statusCode != 200) throw Exception('Failed (${res.statusCode})');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['favorite'] as bool?) ?? favorite;
  }

  Future<List<Itinerary>> fetchFavorites() async {
    final res = await _client.get(_uri('/favorites/'), headers: await _authHeaders());
    if (res.statusCode == 401) throw Exception('Unauthorized');
    if (res.statusCode != 200) throw Exception('Failed (${res.statusCode})');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Itinerary.fromJson(e as Map<String, dynamic>)).toList();
  }
}

