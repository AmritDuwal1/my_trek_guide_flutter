import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tour_mobile/models/nepal_place.dart';
import 'package:tour_mobile/services/itinerary_service.dart';
import 'package:tour_mobile/screens/map/in_app_route_navigation_screen.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:tour_mobile/widgets/api_offline_block.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _everestBaseCampTrekId = 'everest-base-camp-trek';

  final _service = ItineraryService();
  late Future<List<NepalPlace>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchNepalPlaces();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchNepalPlaces();
    });
    await _future;
  }

  /// Google Maps cannot route the Khumbu foot trail; for EBC we pass our geocoded
  /// corridor as walking origin / waypoints / destination (approximate).
  Uri _everestClassicWalkingUri(List<NepalRoutePoint> path) {
    final origin = path.first;
    final dest = path.last;
    final middle = path.sublist(1, path.length - 1);
    final sampled = _evenSampleMiddleWaypoints(middle, 10);
    final q = <String, String>{
      'api': '1',
      'travelmode': 'walking',
      'origin': '${origin.lat},${origin.lng}',
      'destination': '${dest.lat},${dest.lng}',
    };
    if (sampled.isNotEmpty) {
      q['waypoints'] = sampled.map((p) => '${p.lat},${p.lng}').join('|');
    }
    return Uri.https('www.google.com', '/maps/dir/', q);
  }

  List<NepalRoutePoint> _evenSampleMiddleWaypoints(List<NepalRoutePoint> pts, int max) {
    if (pts.isEmpty || max <= 0) return [];
    if (pts.length <= max) return pts;
    final out = <NepalRoutePoint>[];
    for (var i = 0; i < max; i++) {
      final idx = ((i / (max - 1)) * (pts.length - 1)).round();
      out.add(pts[idx]);
    }
    final deduped = <NepalRoutePoint>[];
    NepalRoutePoint? prev;
    for (final p in out) {
      if (prev != null && prev.lat == p.lat && prev.lng == p.lng) continue;
      deduped.add(p);
      prev = p;
    }
    return deduped;
  }

  Uri _mapsDirectionsUri(NepalPlace place) {
    if (place.id == _everestBaseCampTrekId &&
        place.routePath != null &&
        place.routePath!.length >= 2) {
      return _everestClassicWalkingUri(place.routePath!);
    }

    late final double destLat;
    late final double destLng;
    if (place.type == 'Trek') {
      if (place.vehicleLat != null && place.vehicleLng != null) {
        destLat = place.vehicleLat!;
        destLng = place.vehicleLng!;
      } else if (place.routePath != null && place.routePath!.isNotEmpty) {
        destLat = place.routePath!.first.lat;
        destLng = place.routePath!.first.lng;
      } else {
        destLat = place.lat;
        destLng = place.lng;
      }
    } else {
      destLat = place.lat;
      destLng = place.lng;
    }

    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$destLat,$destLng',
      'travelmode': 'driving',
    });
  }

  Future<void> _navigateTo(NepalPlace place) async {
    final uri = _mapsDirectionsUri(place);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open maps app');
    }
  }

  void _showPlaceSheet(NepalPlace place) {
    final nav = Navigator.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: TravelColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${place.type} · ${place.province}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TravelColors.muted),
              ),
              const SizedBox(height: 10),
              Text(
                place.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  nav.pop();
                  nav.push(
                    MaterialPageRoute<void>(
                      builder: (_) => InAppRouteNavigationScreen(place: place),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: TravelColors.navActive,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Navigate in app'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    nav.pop();
                    await _navigateTo(place);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TravelColors.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: TravelColors.line),
                  ),
                  child: Text(
                    place.id == _everestBaseCampTrekId
                        ? 'Google Maps — walking EBC (approx.)'
                        : place.type == 'Trek'
                            ? 'Google Maps — trailhead'
                            : 'Google Maps — directions',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TravelColors.canvas,
      child: FutureBuilder<List<NepalPlace>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: TravelColors.navActive));
          }
          if (snapshot.hasError) {
            return ApiOfflineBlock(onRetry: _reload);
          }
          final places = snapshot.data ?? const <NepalPlace>[];
          if (places.isEmpty) {
            return Center(child: Text('No places to show.', style: Theme.of(context).textTheme.bodyLarge));
          }

          final center = const LatLng(28.3949, 84.1240); // Nepal centroid-ish

          final markers = places.map((p) {
            final isTrek = p.type == 'Trek';
            final color = isTrek ? TravelColors.accent : TravelColors.navActive;
            return Marker(
              point: LatLng(p.lat, p.lng),
              width: 42,
              height: 42,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showPlaceSheet(p),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    isTrek ? Icons.hiking_rounded : Icons.place_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            );
          }).toList();

          final polylines = <Polyline<Object>>[
            for (final p in places)
              if (p.type == 'Trek' && p.routePath != null && p.routePath!.length >= 2)
                Polyline<Object>(
                  points: p.routePath!.map((e) => LatLng(e.lat, e.lng)).toList(),
                  strokeWidth: 3.5,
                  color: TravelColors.accent.withValues(alpha: 0.62),
                ),
          ];

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 6.6,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tour.tour_mobile',
                  ),
                  if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.paddingOf(context).top + 12,
                child: Row(
                  children: [
                    Material(
                      color: TravelColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      child: IconButton(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Reload',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: TravelColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.08),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            '${places.length} places in Nepal',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                bottom: 18,
                child: _Legend(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: TravelColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Legend', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: TravelColors.navActive),
                const SizedBox(width: 8),
                const Text('Places'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: TravelColors.accent),
                const SizedBox(width: 8),
                const Text('Treks'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

