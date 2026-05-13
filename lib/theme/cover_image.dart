/// Hero image per itinerary.
///
/// Prefer the explicit `image_url` / `image_urls` provided by the API
/// (canonical Wikipedia / Wikimedia Commons photo of the specific place).
/// Fall back to keyword-based search only when no explicit URL is available.

/// Single URL for the cover, falling back to the keyword-based default.
String itineraryCoverUrl(String itineraryId, {String? explicitUrl}) {
  if (explicitUrl != null && explicitUrl.trim().isNotEmpty) return explicitUrl;
  return itineraryCoverUrls(itineraryId).first;
}

/// Ordered list of URLs to try in sequence (used with [NetworkImageWithFallback]).
List<String> itineraryCoverUrls(
  String itineraryId, {
  List<String> preferred = const [],
}) {
  final id = itineraryId.trim().toLowerCase();

  final out = <String>[
    for (final u in preferred)
      if (u.trim().isNotEmpty) u.trim(),
  ];

  final query = switch (id) {
    _ when id.contains('nagarkot') => 'nagarkot nepal sunrise himalayas viewpoint',
    _ when id.contains('phew') || id.contains('phewa') => 'phewa lake pokhara nepal',
    _ when id.contains('annapurna') => 'annapurna trek nepal mountains trail',
    _ when id.contains('everest') => 'everest base camp trek nepal mountains',
    _ when id.contains('chitwan') => 'chitwan national park nepal wildlife',
    _ when id.contains('lumbini') => 'lumbini nepal buddhist monastery',
    _ when id.contains('boudha') || id.contains('boudhanath') => 'boudhanath stupa kathmandu nepal',
    _ when id.contains('swayambhu') || id.contains('swayambhunath') => 'swayambhunath stupa kathmandu nepal',
    _ when id.contains('durbar') => 'durbar square kathmandu nepal temple',
    _ when id.contains('pokhara') => 'pokhara nepal lake mountains',
    _ when id.contains('bandipur') => 'bandipur nepal hilltop village',
    _ when id.contains('bhaktapur') => 'bhaktapur durbar square nepal',
    _ when id.contains('patan') => 'patan durbar square nepal',
    _ => 'nepal travel mountains temples',
  };

  final safe = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), 'x');
  // Last-resort placeholder. Unsplash's "source" endpoint is deprecated and
  // returns random photos, so we only use Picsum as a generic backdrop and
  // never as a primary "this is the place" image.
  out.add('https://picsum.photos/seed/${safe.isEmpty ? 'tour' : safe}/960/640');

  // Add the Wikipedia-keyword-search redirect as an extra hint when the API
  // didn't supply a URL. Note: this is not a guaranteed image; it relies on
  // the `preferred` list above for the real per-place photo.
  if (preferred.isEmpty) {
    final encoded = Uri.encodeComponent(query);
    out.insert(0, 'https://commons.wikimedia.org/wiki/Special:FilePath/$encoded.jpg?width=960');
  }

  return out;
}

/// Smaller thumbs for browse categories.
String categoryThumbUrl(String seed) {
  return categoryThumbUrls(seed).first;
}

List<String> categoryThumbUrls(String seed) {
  final s = seed.trim().toLowerCase();
  final safe = s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), 'x');
  return [
    'https://picsum.photos/seed/${safe.isEmpty ? 'tour' : safe}/160/160',
  ];
}
