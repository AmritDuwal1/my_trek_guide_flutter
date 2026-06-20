import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tour_mobile/config/api_config.dart';
import 'package:tour_mobile/models/app_country.dart';
import 'package:tour_mobile/models/world_place.dart';
import 'package:tour_mobile/services/logging_http_client.dart';

class PlaceService {
  PlaceService({http.Client? client}) : _client = client ?? LoggingHttpClient();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${apiBaseUrl()}$path');

  Future<List<AppCountry>> fetchCountries() async {
    final res = await _client.get(_uri('/countries/'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load countries (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => AppCountry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorldPlace>> fetchWorldPlaces(String countryCode) async {
    final code = countryCode.toUpperCase();
    if (code == 'NP') {
      final res = await _client.get(_uri('/nepal/places/'));
      if (res.statusCode != 200) {
        throw Exception('Failed to load places (${res.statusCode})');
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return WorldPlace(
          id: m['id'] as String,
          name: m['name'] as String,
          countryCode: 'NP',
          region: m['province'] as String? ?? '',
          type: m['type'] as String? ?? '',
          summary: m['summary'] as String? ?? '',
          lat: (m['lat'] as num).toDouble(),
          lng: (m['lng'] as num).toDouble(),
          imageUrls: const [],
        );
      }).toList();
    }

    final uri = _uri('/world/places/').replace(
      queryParameters: {'country': code},
    );
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load places (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => WorldPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
