/// Deterministic hero image per itinerary (Picsum `seed` must stay URL-safe).
String itineraryCoverUrl(String itineraryId) {
  final safe = itineraryId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), 'x');
  final seed = safe.isEmpty ? 'tour' : safe;
  return 'https://picsum.photos/seed/$seed/960/640';
}
