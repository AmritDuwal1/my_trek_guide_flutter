import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tour_mobile/models/nepal_place.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

/// Full-screen map + lightweight “navigation” inside the app (OSM + our polyline).
///
/// GPS shows position vs the corridor when permission is granted; routing is still
/// an approximation along vertices — always follow real trail signage locally.
class InAppRouteNavigationScreen extends StatefulWidget {
  const InAppRouteNavigationScreen({super.key, required this.place});

  final NepalPlace place;

  @override
  State<InAppRouteNavigationScreen> createState() => _InAppRouteNavigationScreenState();
}

class _InAppRouteNavigationScreenState extends State<InAppRouteNavigationScreen> {
  final _mapController = MapController();

  StreamSubscription<Position>? _posSub;
  LatLng? _user;

  static const Distance _distCalc = Distance();

  List<LatLng> get _points => _routePoints(widget.place);

  static List<LatLng> _routePoints(NepalPlace place) {
    if (place.routePath != null && place.routePath!.length >= 2) {
      return place.routePath!.map((e) => LatLng(e.lat, e.lng)).toList();
    }
    if (place.type == 'Trek' && place.vehicleLat != null && place.vehicleLng != null) {
      return [
        LatLng(place.vehicleLat!, place.vehicleLng!),
        LatLng(place.lat, place.lng),
      ];
    }
    return [LatLng(place.lat, place.lng)];
  }

  double _polylineLengthKm(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    double km = 0;
    for (var i = 0; i < pts.length - 1; i++) {
      km += _distCalc.as(LengthUnit.Kilometer, pts[i], pts[i + 1]);
    }
    return km;
  }

  double? _remainingKmAlongPolyline(List<LatLng> pts, LatLng user) {
    if (pts.length < 2) return null;
    var bestI = 0;
    var bestM = double.infinity;
    for (var i = 0; i < pts.length; i++) {
      final m = _distCalc.as(LengthUnit.Meter, user, pts[i]);
      if (m < bestM) {
        bestM = m;
        bestI = i;
      }
    }
    double remaining = 0;
    for (var j = bestI; j < pts.length - 1; j++) {
      remaining += _distCalc.as(LengthUnit.Kilometer, pts[j], pts[j + 1]);
    }
    return remaining;
  }

  void _fitRoute() {
    final pts = _points;
    if (pts.isEmpty) return;
    final padTop = MediaQuery.paddingOf(context).top + kToolbarHeight + 12;
    final padBottom = 200.0;
    final bounds = pts.length >= 2
        ? LatLngBounds.fromPoints(pts)
        : LatLngBounds(
            LatLng(pts.first.latitude - 0.03, pts.first.longitude - 0.03),
            LatLng(pts.first.latitude + 0.03, pts.first.longitude + 0.03),
          );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.only(left: 16, right: 16, top: padTop, bottom: padBottom),
      ),
    );
  }

  Future<void> _tryStartLocation() async {
    if (kIsWeb) return;
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn || !mounted) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _user = LatLng(pos.latitude, pos.longitude));

      await _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 25,
        ),
      ).listen((p) {
        if (!mounted) return;
        setState(() => _user = LatLng(p.latitude, p.longitude));
      });
    } catch (_) {
      /* ignore — offline / denied */
    }
  }

  void _centerOnUser() {
    final u = _user;
    if (u == null) return;
    _mapController.move(u, 14);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitRoute();
      _tryStartLocation();
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pts = _points;
    final lenKm = _polylineLengthKm(pts);
    final remainingKm = _user != null && pts.length >= 2 ? _remainingKmAlongPolyline(pts, _user!) : null;

    final markers = <Marker>[
      Marker(
        width: 36,
        height: 36,
        point: pts.first,
        alignment: Alignment.center,
        child: Icon(Icons.flag_rounded, color: Colors.green.shade700, size: 30),
      ),
      Marker(
        width: 36,
        height: 36,
        point: pts.last,
        alignment: Alignment.center,
        child: Icon(Icons.place_rounded, color: TravelColors.navActive, size: 34),
      ),
    ];

    final u = _user;
    if (u != null) {
      markers.add(
        Marker(
          width: 28,
          height: 28,
          point: u,
          alignment: Alignment.center,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bounds = pts.length >= 2
        ? LatLngBounds.fromPoints(pts)
        : LatLngBounds(
            LatLng(pts.first.latitude - 0.03, pts.first.longitude - 0.03),
            LatLng(pts.first.latitude + 0.03, pts.first.longitude + 0.03),
          );

    return Scaffold(
      backgroundColor: TravelColors.canvas,
      appBar: AppBar(
        title: Text(widget.place.name),
        actions: [
          IconButton(
            tooltip: 'Fit route',
            icon: const Icon(Icons.fit_screen_rounded),
            onPressed: _fitRoute,
          ),
          IconButton(
            tooltip: 'My location',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _user != null ? _centerOnUser : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
                  bottom: 200,
                ),
              ),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mytrekguide.app',
              ),
              if (pts.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline<Object>(
                      points: pts,
                      strokeWidth: 5,
                      color: TravelColors.accent.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Material(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                color: TravelColors.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'In-app route',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pts.length >= 2
                            ? 'Approximate path length: ${lenKm.toStringAsFixed(1)} km'
                            : 'Destination marker — open catalogue route on larger trips.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted, height: 1.35),
                      ),
                      if (remainingKm != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Rough remaining along path: ${remainingKm.toStringAsFixed(1)} km',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (_user == null && !kIsWeb) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Enable location permission to see your position on this map.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Outdoor trails are not turn-by-turn roads — use this as a guide only.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: TravelColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
