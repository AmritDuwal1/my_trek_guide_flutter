class WorldPlace {
  const WorldPlace({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.region,
    required this.type,
    required this.summary,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.imageUrls = const [],
  });

  final String id;
  final String name;
  final String countryCode;
  final String region;
  final String type;
  final String summary;
  final double lat;
  final double lng;
  final String? imageUrl;
  final List<String> imageUrls;

  factory WorldPlace.fromJson(Map<String, dynamic> json) {
    final urls = (json['image_urls'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    final rawUrl = json['image_url'] as String?;
    return WorldPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      countryCode: (json['country_code'] as String? ?? '').toUpperCase(),
      region: json['region'] as String? ?? '',
      type: json['type'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      imageUrl: (rawUrl?.trim().isEmpty ?? true) ? null : rawUrl,
      imageUrls: urls,
    );
  }
}
