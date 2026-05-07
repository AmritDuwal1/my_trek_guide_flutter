class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAtMs,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final int createdAtMs;
  final bool read;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAtMs: createdAtMs,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAtMs': createdAtMs,
        'read': read,
      };

  static AppNotification fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAtMs: (json['createdAtMs'] as num).toInt(),
      read: json['read'] as bool? ?? false,
    );
  }
}

