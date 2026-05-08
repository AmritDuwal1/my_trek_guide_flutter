/// Hero image per itinerary.
///
/// We previously used Picsum seeds which often produced unrelated photos.
/// This version uses query-based images with Nepal-specific keywords.
String itineraryCoverUrl(String itineraryId) {
  return itineraryCoverUrls(itineraryId).first;
}

List<String> itineraryCoverUrls(String itineraryId) {
  final id = itineraryId.trim().toLowerCase();

  // Curated, high-signal queries for better relevance.
  // (No hardcoded copyrighted images; uses a public photo source endpoint.)
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

  // Use a deterministic-ish "sig" so the same id tends to keep the same photo.
  // (source.unsplash.com supports `sig` to vary results; we derive it from the id.)
  final sig = id.codeUnits.fold<int>(0, (a, b) => (a + b) % 1000);
  final encoded = Uri.encodeComponent(query);
  final unsplash = 'https://source.unsplash.com/960x640/?$encoded&sig=$sig';

  // Fallback (more reliable host; may be less relevant).
  final safe = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), 'x');
  final picsum = 'https://picsum.photos/seed/${safe.isEmpty ? 'tour' : safe}/960/640';

  return [unsplash, picsum];
}

/// Smaller thumbs for browse categories.
String categoryThumbUrl(String seed) {
  return categoryThumbUrls(seed).first;
}

List<String> categoryThumbUrls(String seed) {
  final s = seed.trim().toLowerCase();
  final query = switch (s) {
    _ when s.contains('trek') => 'nepal trekking trail mountains',
    _ when s.contains('temple') || s.contains('heritage') => 'nepal temple heritage',
    _ when s.contains('wild') || s.contains('rhino') => 'nepal wildlife rhino',
    _ when s.contains('lake') || s.contains('phewa') => 'nepal lake',
    _ => 'nepal travel',
  };
  final sig = s.codeUnits.fold<int>(0, (a, b) => (a + b) % 1000);
  final encoded = Uri.encodeComponent(query);
  final unsplash = 'https://source.unsplash.com/160x160/?$encoded&sig=$sig';
  final safe = s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), 'x');
  final picsum = 'https://picsum.photos/seed/${safe.isEmpty ? 'tour' : safe}/160/160';
  return [unsplash, picsum];
}
