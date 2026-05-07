import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tour_mobile/config/api_config.dart';
import 'package:tour_mobile/services/logging_http_client.dart';
import 'package:tour_mobile/models/itinerary.dart';
import 'package:tour_mobile/models/nepal_place.dart';

class ItineraryService {
  ItineraryService({http.Client? client}) : _client = client ?? LoggingHttpClient();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${apiBaseUrl()}$path');

  Future<List<Itinerary>> fetchItineraries() async {
    final res = await _client.get(_uri('/itineraries'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load itineraries (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Itinerary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Itinerary> fetchItinerary(String id) async {
    final res = await _client.get(_uri('/itineraries/$id'));
    if (res.statusCode == 404) {
      throw Exception('Itinerary not found');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to load itinerary (${res.statusCode})');
    }
    return Itinerary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Full Nepal catalogue (same `id` as [fetchItinerary]).
  Future<List<NepalPlace>> fetchNepalPlaces() async {
    final res = await _client.get(_uri('/nepal/places/'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load Nepal places (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => NepalPlace.fromJson(e as Map<String, dynamic>)).toList();
  }
}
