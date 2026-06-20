class AppCountry {
  const AppCountry({
    required this.code,
    required this.name,
    required this.emoji,
    required this.continent,
    required this.capital,
    required this.lat,
    required this.lng,
    required this.description,
    required this.currency,
    required this.language,
  });

  final String code;
  final String name;
  final String emoji;
  final String continent;
  final String capital;
  final double lat;
  final double lng;
  final String description;
  final String currency;
  final String language;

  factory AppCountry.fromJson(Map<String, dynamic> json) {
    return AppCountry(
      code: json['code'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '',
      continent: json['continent'] as String? ?? '',
      capital: json['capital'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      language: json['language'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'emoji': emoji,
        'continent': continent,
        'capital': capital,
        'lat': lat,
        'lng': lng,
        'description': description,
        'currency': currency,
        'language': language,
      };

  @override
  bool operator ==(Object other) =>
      other is AppCountry && other.code == code;

  @override
  int get hashCode => code.hashCode;

  static const AppCountry nepal = AppCountry(
    code: 'NP',
    name: 'Nepal',
    emoji: '🇳🇵',
    continent: 'Asia',
    capital: 'Kathmandu',
    lat: 28.3949,
    lng: 84.1240,
    description: 'Home to eight of the world\'s ten highest peaks.',
    currency: 'NPR',
    language: 'Nepali',
  );
}
