class Stop {
  const Stop({this.time, required this.title, this.notes});

  final String? time;
  final String title;
  final String? notes;

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      time: json['time'] as String?,
      title: json['title'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class DayPlan {
  const DayPlan({
    required this.day,
    required this.title,
    required this.stops,
  });

  final int day;
  final String title;
  final List<Stop> stops;

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final raw = json['stops'] as List<dynamic>? ?? const [];
    return DayPlan(
      day: (json['day'] as num).toInt(),
      title: json['title'] as String,
      stops: raw
          .map((e) => Stop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Itinerary {
  const Itinerary({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.days,
    required this.country,
    required this.rating,
    this.province,
  });

  final String id;
  final String title;
  final String summary;
  final String category;
  final List<DayPlan> days;
  final String country;
  final double rating;
  final String? province;

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    final raw = json['days'] as List<dynamic>? ?? const [];
    return Itinerary(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      category: json['category'] as String,
      days: raw
          .map((e) => DayPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      country: json['country'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      province: json['province'] as String?,
    );
  }
}
