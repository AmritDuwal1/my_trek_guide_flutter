import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:tour_mobile/models/nepal_place.dart';
import 'package:tour_mobile/models/world_place.dart';
import 'package:tour_mobile/screens/country_picker_screen.dart';
import 'package:tour_mobile/screens/map/in_app_route_navigation_screen.dart';
import 'package:tour_mobile/services/itinerary_service.dart';
import 'package:tour_mobile/services/place_service.dart';
import 'package:tour_mobile/stores/country_store.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:tour_mobile/widgets/api_offline_block.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.focusPlaceId});

  /// When set (e.g. from an itinerary detail), the map centers on this place.
  final String? focusPlaceId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _itineraryService = ItineraryService();
  final _placeService = PlaceService();
  final _countryStore = CountryStore.instance;
  late Future<List<WorldPlace>> _future;
  final _mapController = MapController();
  double _zoom = 5.0;
  bool _appliedFocusPlace = false;

  static const double _minZoomForTrekPolylines = 10.0;

  @override
  void initState() {
    super.initState();
    _zoom = _defaultZoomForCountry(_countryStore.selected.code);
    _loadForCurrentCountry();
    _countryStore.addListener(_onCountryChanged);
  }

  @override
  void dispose() {
    _countryStore.removeListener(_onCountryChanged);
    super.dispose();
  }

  void _onCountryChanged() {
    setState(() {
      _zoom = _defaultZoomForCountry(_countryStore.selected.code);
      _appliedFocusPlace = false;
    });
    _loadForCurrentCountry();
  }

  double _defaultZoomForCountry(String code) {
    // Larger countries get lower initial zoom
    const large = {'US', 'CA', 'BR', 'AU', 'CN', 'IN'};
    const medium = {'FR', 'ES', 'DE', 'TR', 'ZA', 'MX', 'PE'};
    if (large.contains(code)) return 4.0;
    if (medium.contains(code)) return 5.2;
    return 6.2;
  }

  void _loadForCurrentCountry() {
    final code = _countryStore.selected.code;
    Future<List<WorldPlace>> f;
    if (code == 'NP') {
      f = _itineraryService.fetchNepalPlaces().then((places) =>
          places.map((p) => WorldPlace(
                id: p.id,
                name: p.name,
                countryCode: 'NP',
                region: p.province,
                type: p.type,
                summary: p.summary,
                lat: p.lat,
                lng: p.lng,
              )).toList());
    } else {
      f = _placeService.fetchWorldPlaces(code);
    }
    setState(() {
      _future = f;
    });
    f.then((places) {
      if (!mounted) return;
      _maybeFocusPlace(places);
      if (widget.focusPlaceId == null || widget.focusPlaceId!.isEmpty) {
        _fitMapToPlaces(places);
      }
    }).catchError((_) {});
  }

  void _centerOnCountry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = _countryStore.selected;
      _mapController.move(LatLng(c.lat, c.lng), _zoom);
    });
  }

  void _fitMapToPlaces(List<WorldPlace> places) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (places.isEmpty) {
        _centerOnCountry();
        return;
      }
      if (places.length == 1) {
        final p = places.first;
        _mapController.move(LatLng(p.lat, p.lng), 10);
        setState(() {
          _zoom = 10;
        });
        return;
      }
      final coords = places.map((p) => LatLng(p.lat, p.lng)).toList();
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: coords,
          padding: const EdgeInsets.only(top: 120, bottom: 100, left: 32, right: 32),
        ),
      );
    });
  }

  Future<void> _reload() async {
    setState(() => _appliedFocusPlace = false);
    _loadForCurrentCountry();
    await _future;
  }

  // ── Place styling ─────────────────────────────────────────────────────────

  ({Color color, IconData icon}) _styleForType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'trek':
        return (color: TravelColors.accent, icon: Icons.hiking_rounded);
      case 'heritage':
        return (color: const Color(0xFFFB8C00), icon: Icons.account_balance_rounded);
      case 'national park':
        return (color: const Color(0xFF43A047), icon: Icons.forest_rounded);
      case 'lake':
        return (color: const Color(0xFF00ACC1), icon: Icons.water_rounded);
      case 'beach':
        return (color: const Color(0xFF039BE5), icon: Icons.beach_access_rounded);
      case 'island':
        return (color: const Color(0xFF0097A7), icon: Icons.sailing_rounded);
      case 'pilgrimage':
        return (color: const Color(0xFFE65100), icon: Icons.temple_hindu_rounded);
      case 'city':
        return (color: const Color(0xFF5E35B1), icon: Icons.location_city_rounded);
      case 'viewpoint':
        return (color: const Color(0xFF546E7A), icon: Icons.landscape_rounded);
      case 'adventure':
        return (color: const Color(0xFFE53935), icon: Icons.kayaking_rounded);
      case 'hill station':
        return (color: const Color(0xFF6D4C41), icon: Icons.cottage_rounded);
      default:
        return (color: TravelColors.navActive, icon: Icons.place_rounded);
    }
  }

  Marker _placeMarker({
    required WorldPlace place,
    required bool showLabel,
    double size = 42,
  }) {
    final style = _styleForType(place.type);
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
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TravelColors.ink),
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

  // ── Focus ─────────────────────────────────────────────────────────────────

  void _maybeFocusPlace(List<WorldPlace> places) {
    final id = widget.focusPlaceId;
    if (id == null || id.isEmpty || _appliedFocusPlace) return;
    WorldPlace? match;
    for (final p in places) {
      if (p.id == id) {
        match = p;
        break;
      }
    }
    if (match == null) {
      _appliedFocusPlace = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('This place could not be found on the map.')),
        );
      });
      return;
    }
    _appliedFocusPlace = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final point = LatLng(match!.lat, match.lng);
      _mapController.move(point, 12);
      setState(() => _zoom = 12);
      _showPlaceSheet(match);
    });
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  void _showPlaceSheet(WorldPlace place) {
    final nav = Navigator.of(context);
    final isNepal = place.countryCode == 'NP';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: TravelColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${place.type} · ${place.region}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: TravelColors.muted),
              ),
              const SizedBox(height: 10),
              Text(
                place.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (isNepal)
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          // Fetch the full NepalPlace for in-app navigation
                          nav.pop();
                          final itService = ItineraryService();
                          final places = await itService.fetchNepalPlaces();
                          if (!mounted) return;
                          NepalPlace? np;
                          try {
                            np = places.firstWhere((p) => p.id == place.id);
                          } catch (_) {}
                          if (np != null && mounted) {
                            nav.push(MaterialPageRoute<void>(
                              builder: (_) =>
                                  InAppRouteNavigationScreen(place: np!),
                            ));
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: TravelColors.navActive,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('In-app nav'),
                      ),
                    ),
                  if (isNepal) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        nav.pop();
                        await _openGoogleMaps(place.lat, place.lng);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        side: const BorderSide(color: TravelColors.line),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _countryStore,
      builder: (context, _) {
        return ColoredBox(
          color: TravelColors.canvas,
          child: FutureBuilder<List<WorldPlace>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: TravelColors.navActive));
              }
              if (snapshot.hasError) {
                return ApiOfflineBlock(onRetry: _reload);
              }
              final places = snapshot.data ?? const <WorldPlace>[];

              final country = _countryStore.selected;
              final center = LatLng(country.lat, country.lng);
              final showLabel = _zoom >= 8.5;
              final showTrekPolylines = _zoom >= _minZoomForTrekPolylines;

              final markers = <Marker>[
                for (final p in places)
                  _placeMarker(place: p, showLabel: showLabel),
              ];

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _zoom,
                      interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all),
                      onPositionChanged: (pos, _) {
                        final z = pos.zoom;
                        if ((z - _zoom).abs() >= 0.05) {
                          setState(() => _zoom = z);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.tour.tour_mobile',
                      ),
                      if (showTrekPolylines && places.isNotEmpty)
                        PolylineLayer<Object>(polylines: const []),
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
                                color: TravelColors.navActive
                                    .withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${clustered.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  // Top bar
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CountryPickerScreen(),
                                ),
                              );
                            },
                            child: Material(
                              color: TravelColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 2,
                              shadowColor:
                                  Colors.black.withValues(alpha: 0.08),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 11),
                                child: Row(
                                  children: [
                                    Text(country.emoji,
                                        style:
                                            const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${places.length} places · ${country.name}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.expand_more_rounded,
                                        size: 18, color: TravelColors.muted),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Legend
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
      },
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

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
            Text('Map legend',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final entry in const [
              MapEntry(TravelColors.navActive, 'Places'),
              MapEntry(TravelColors.accent, 'Treks'),
              MapEntry(Color(0xFF039BE5), 'Beaches'),
              MapEntry(Color(0xFF5E35B1), 'Cities'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Dot(color: entry.key),
                    const SizedBox(width: 8),
                    Text(entry.value,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
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
