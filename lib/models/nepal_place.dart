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
    this.vehicleLat,
    this.vehicleLng,
    this.routePath,
  });

  final String id;
  final String name;
  final String province;
  final String type;
  final String summary;
  final double lat;
  final double lng;
  final double? vehicleLat;
  final double? vehicleLng;
  /// Approximate trek trace from API (`route_path`) for map polylines.
  final List<NepalRoutePoint>? routePath;

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

    return NepalPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      province: json['province'] as String,
      type: json['type'] as String,
      summary: json['summary'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      vehicleLat: (json['vehicle_lat'] as num?)?.toDouble(),
      vehicleLng: (json['vehicle_lng'] as num?)?.toDouble(),
      routePath: routePath,
    );
  }
}
