import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_mobile/models/app_country.dart';

class CountryStore extends ChangeNotifier {
  CountryStore._();

  static final CountryStore instance = CountryStore._();

  AppCountry _selected = AppCountry.nepal;
  List<AppCountry> _all = [];
  bool _locationChecked = false;

  AppCountry get selected => _selected;
  List<AppCountry> get allCountries => _all;

  static const _kSelectedKey = 'selected_country_json';

  // ── Initialise ─────────────────────────────────────────────────────────

  Future<void> init(List<AppCountry> countries) async {
    _all = countries;
    await _loadPersistedCountry();
    notifyListeners();
  }

  Future<void> _loadPersistedCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSelectedKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _selected = AppCountry.fromJson(map);
        return;
      }
    } catch (_) {}
    // Keep Nepal as default
  }

  // ── Select ──────────────────────────────────────────────────────────────

  Future<void> select(AppCountry country) async {
    if (_selected == country) return;
    _selected = country;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSelectedKey, jsonEncode(country.toJson()));
    } catch (_) {}
  }

  // ── Location detection ──────────────────────────────────────────────────

  /// Request location permission and detect user's country.
  /// Returns the detected [AppCountry] if successful, null otherwise.
  /// Does NOT auto-select — caller decides whether to prompt or auto-apply.
  Future<AppCountry?> detectCountry() async {
    if (_locationChecked) return null;
    _locationChecked = true;

    try {
      // Check / request permission.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return null;
      final isoCode = placemarks.first.isoCountryCode?.toUpperCase() ?? '';
      if (isoCode.isEmpty) return null;

      return _matchCountry(isoCode);
    } catch (_) {
      return null;
    }
  }

  AppCountry? _matchCountry(String isoCode) {
    try {
      return _all.firstWhere((c) => c.code == isoCode);
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Map<String, List<AppCountry>> groupedByContinent() {
    final map = <String, List<AppCountry>>{};
    for (final c in _all) {
      map.putIfAbsent(c.continent, () => []).add(c);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }
}
