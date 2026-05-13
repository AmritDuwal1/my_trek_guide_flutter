class NepalRoutePoint {
  const NepalRoutePoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory NepalRoutePoint.fromJson(Map<String, dynamic> json) {
    return NepalRoutePoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class NepalPlace {
  const NepalPlace({
    required this.id,
    required this.name,
    required this.province,
    required this.type,
    required this.summary,
    required this.lat,
    required this.lng,
    this.dayCount,
    this.vehicleLat,
    this.vehicleLng,
    this.routePath,
    this.dayLocations,
  });

  final String id;
  final String name;
  final String province;
  final String type;
  final String summary;
  final double lat;
  final double lng;
  /// Number of days in the itinerary (from `/itineraries/<id>/day_count`).
  final int? dayCount;
  final double? vehicleLat;
  final double? vehicleLng;
  /// Approximate trek trace from API (`route_path`) for map polylines.
  final List<NepalRoutePoint>? routePath;
  /// Per-day overnight coordinates (one per day) for placing day pins on
  /// the in-app navigation map. Index `i` is Day `i+1`'s overnight stop.
  final List<NepalRoutePoint>? dayLocations;

  factory NepalPlace.fromJson(Map<String, dynamic> json) {
    List<NepalRoutePoint>? routePath;
    final rawPath = json['route_path'];
    if (rawPath is List<dynamic>) {
      final pts = <NepalRoutePoint>[];
      for (final e in rawPath) {
        if (e is Map<String, dynamic>) {
          pts.add(NepalRoutePoint.fromJson(e));
        }
      }
      if (pts.length >= 2) {
        routePath = pts;
      }
    }

    List<NepalRoutePoint>? dayLocations;
    final rawLocs = json['day_locations'];
    if (rawLocs is List<dynamic>) {
      final pts = <NepalRoutePoint>[];
      for (final e in rawLocs) {
        if (e is Map<String, dynamic>) {
          try {
            pts.add(NepalRoutePoint.fromJson(e));
          } catch (_) {
            // skip malformed entry
          }
        }
      }
      if (pts.isNotEmpty) {
        dayLocations = pts;
      }
    }

    return NepalPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      province: json['province'] as String,
      type: json['type'] as String,
      summary: json['summary'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      dayCount: (json['day_count'] as num?)?.toInt(),
      vehicleLat: (json['vehicle_lat'] as num?)?.toDouble(),
      vehicleLng: (json['vehicle_lng'] as num?)?.toDouble(),
      routePath: routePath,
      dayLocations: dayLocations,
    );
  }
}
