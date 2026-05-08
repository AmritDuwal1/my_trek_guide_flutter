import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:tour_mobile/models/nepal_place.dart';
import 'package:tour_mobile/screens/map/in_app_route_navigation_screen.dart';
import 'package:tour_mobile/services/itinerary_service.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:tour_mobile/widgets/api_offline_block.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _service = ItineraryService();
  late Future<List<NepalPlace>> _future;
  final _mapController = MapController();
  double _zoom = 6.6;

  Future<void> _openGoogleMapsDirections(NepalPlace place) async {
    final dest = '${place.lat},${place.lng}';
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

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

  ({Color color, IconData icon}) _styleForPlace(NepalPlace p) {
    final t = p.type.trim().toLowerCase();
    if (t == 'trek') {
      return (color: TravelColors.accent, icon: Icons.hiking_rounded);
    }
    if (t.contains('hotel') || t.contains('lodge') || t.contains('guest')) {
      return (color: const Color(0xFF7C4DFF), icon: Icons.hotel_rounded);
    }
    if (t.contains('waterfall') || t.contains('falls')) {
      return (color: const Color(0xFF1E88E5), icon: Icons.waterfall_chart_rounded);
    }
    if (t.contains('lake')) {
      return (color: const Color(0xFF00ACC1), icon: Icons.water_rounded);
    }
    if (t.contains('temple') || t.contains('monastery') || t.contains('stupa')) {
      return (color: const Color(0xFFFB8C00), icon: Icons.temple_buddhist_rounded);
    }
    if (t.contains('view') || t.contains('peak') || t.contains('summit')) {
      return (color: const Color(0xFF546E7A), icon: Icons.landscape_rounded);
    }
    return (color: TravelColors.navActive, icon: Icons.place_rounded);
  }

  Marker _placeMarker({
    required NepalPlace place,
    required bool showLabel,
    double size = 42,
  }) {
    final style = _styleForPlace(place);
    final point = LatLng(place.lat, place.lng);

    Widget pin = DecoratedBox(
      decoration: BoxDecoration(
        color: style.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(style.icon, color: Colors.white, size: size * 0.52),
        ),
      ),
    );

    if (showLabel) {
      pin = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          pin,
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TravelColors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TravelColors.ink),
              ),
            ),
          ),
        ],
      );
    }

    return Marker(
      point: point,
      width: showLabel ? 180 : size,
      height: showLabel ? (size + 34) : size,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _showPlaceSheet(place),
        child: pin,
      ),
    );
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
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
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
                      child: const Text('In-app'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        nav.pop();
                        await _openGoogleMapsDirections(place);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Google Maps'),
                    ),
                  ),
                ],
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

          // Show names on the map (still clustered when zoomed out).
          final showLabel = _zoom >= 8.5;
          final markers = <Marker>[
            for (final p in places) _placeMarker(place: p, showLabel: showLabel),
          ];

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
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 6.6,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  onPositionChanged: (pos, _) {
                    final z = pos.zoom;
                    if ((z - _zoom).abs() >= 0.05) {
                      setState(() => _zoom = z);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tour.tour_mobile',
                  ),
                  if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      markers: markers,
                      maxClusterRadius: 55,
                      size: const Size(44, 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      disableClusteringAtZoom: 14,
                      showPolygon: false,
                      builder: (context, clustered) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: TravelColors.navActive.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${clustered.length}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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

