import 'package:flutter/material.dart';
import 'package:tour_mobile/models/nepal_place.dart';
import 'package:tour_mobile/screens/map/in_app_route_navigation_screen.dart';
import 'package:tour_mobile/services/itinerary_service.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final _service = ItineraryService();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  late Future<List<NepalPlace>> _future;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _future = _service.fetchNepalPlaces();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<NepalPlace> _filter(List<NepalPlace> places, String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return places;
    return places.where((p) {
      final name = p.name.toLowerCase();
      final type = p.type.toLowerCase();
      final province = p.province.toLowerCase();
      return name.contains(s) || type.contains(s) || province.contains(s);
    }).toList();
  }

  void _open(NepalPlace p) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InAppRouteNavigationScreen(place: p),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.canvas,
      appBar: AppBar(
        title: const Text('Search places'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: (v) => setState(() => _q = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name, type, province…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: TravelColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: TravelColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: TravelColors.navActive.withValues(alpha: 0.9), width: 1.4),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<NepalPlace>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: TravelColors.navActive));
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Could not load places. Check your API connection.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TravelColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final places = snap.data ?? const <NepalPlace>[];
                final filtered = _filter(places, _q);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No places found.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TravelColors.muted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _open(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: TravelColors.navActive.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.place_rounded, color: TravelColors.navActive),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.type} · ${p.province}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: TravelColors.muted),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

