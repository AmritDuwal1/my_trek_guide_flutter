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
  static const LatLng _kathmandu = LatLng(27.7172, 85.3240);

  List<LatLng> get _points => _routePoints(widget.place);

  static int _dayCountFor(NepalPlace place, List<LatLng> pts) {
    final dc = place.dayCount;
    if (dc != null && dc >= 1) return dc;
    if (pts.length < 3) return 1;
    return 1;
  }

  Widget _dayPin({
    required String label,
    required bool isLast,
  }) {
    final bg = isLast ? TravelColors.navActive : TravelColors.accent;
    final isMulti = label.length > 2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(isMulti ? 18 : 999),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMulti ? 8 : 0),
        child: SizedBox(
          height: 34,
          width: isMulti ? null : 34,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Treats coords within ~150 m as the same overnight stop. Avoids
  /// near-identical curated entries (e.g. "Kyanjin" vs "Tserko Ri side
  /// hike from Kyanjin") rendering as separate, overlapping pins.
  bool _sameStop(LatLng a, LatLng b) {
    return _distCalc.as(LengthUnit.Meter, a, b) < 150;
  }

  /// Format days for a grouped pin: [5] → "5", [4,5] → "4-5",
  /// [4,5,7] → "4-5,7".
  String _formatDayLabel(List<int> days) {
    if (days.isEmpty) return '';
    final sorted = List<int>.from(days)..sort();
    final parts = <String>[];
    var rangeStart = sorted.first;
    var prev = sorted.first;
    for (var i = 1; i <= sorted.length; i++) {
      final isEnd = i == sorted.length;
      if (!isEnd && sorted[i] == prev + 1) {
        prev = sorted[i];
        continue;
      }
      parts.add(rangeStart == prev ? '$rangeStart' : '$rangeStart-$prev');
      if (!isEnd) {
        rangeStart = sorted[i];
        prev = sorted[i];
      }
    }
    return parts.join(',');
  }

  /// Trims the day positions to the outbound leg (start → farthest
  /// stop, including consecutive same-stop acclimatisation days at
  /// the peak), then merges co-located days into single pins. Return
  /// days are intentionally omitted: their villages already have a
  /// pin from the outbound leg, so showing them again just stacks pins
  /// and hides earlier days behind later ones.
  ///
  /// Important: the *last* day is excluded from "destination" candidates.
  /// For multi-day treks the last day is almost always a return to
  /// Kathmandu/Pokhara, which can be geographically farther from the
  /// trailhead than the real trek destination (e.g. Kathmandu is ~50 km
  /// south of the Langtang trailhead while Kyanjin Gompa is only ~25 km
  /// north — without this guard, the algorithm would treat Kathmandu as
  /// the destination and never trim anything).
  List<({List<int> days, LatLng pos})> _outboundGroups(List<LatLng> positions) {
    if (positions.isEmpty) return const [];
    if (positions.length == 1) {
      return [(days: [1], pos: positions[0])];
    }

    final start = positions[0];
    final searchEnd = positions.length - 1; // exclude trailing return day
    var bestIdx = 0;
    var bestKm = 0.0;
    for (var i = 0; i < searchEnd; i++) {
      final km = _distCalc.as(LengthUnit.Kilometer, start, positions[i]);
      // `>=` so ties favour the later day (e.g. Tserko Ri Day 5 beats
      // Kyanjin Day 4 when both share coords).
      if (km >= bestKm) {
        bestKm = km;
        bestIdx = i;
      }
    }

    // Extend through subsequent days that stay at the destination
    // (acclimatisation/explore days at the peak).
    var endIdx = bestIdx;
    while (endIdx + 1 < positions.length &&
        _sameStop(positions[endIdx + 1], positions[bestIdx])) {
      endIdx++;
    }

    final groups = <({List<int> days, LatLng pos})>[];
    for (var i = 0; i <= endIdx; i++) {
      final dayNum = i + 1;
      if (groups.isNotEmpty && _sameStop(groups.last.pos, positions[i])) {
        groups.last.days.add(dayNum);
      } else {
        groups.add((days: [dayNum], pos: positions[i]));
      }
    }
    return groups;
  }

  List<Marker> _dayMarkers(List<LatLng> pts) {
    if (pts.isEmpty) return const [];
    final dc = _dayCountFor(widget.place, pts);
    if (dc <= 1 || pts.length < 2) {
      return [
        Marker(
          width: 38,
          height: 38,
          point: pts.first,
          alignment: Alignment.center,
          child: Icon(Icons.place_rounded, color: TravelColors.navActive, size: 34),
        ),
      ];
    }

    // Prefer curated per-day overnight coordinates from the API. This
    // makes Day 1, Day 2, … land on the actual village (e.g. EBC:
    // Phakding, Namche, Tengboche, …). Fallback: even-by-distance
    // along the polyline so pins still appear 1, 2, 3 in order.
    final curated = widget.place.dayLocations;
    final positions = (curated != null && curated.isNotEmpty)
        ? curated.map((e) => LatLng(e.lat, e.lng)).toList()
        : _evenlySpacedPositionsByDistance(pts, dc);

    final groups = _outboundGroups(positions);

    final markers = <Marker>[];
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final label = _formatDayLabel(List<int>.from(g.days));
      final isLast = i == groups.length - 1;
      final width = label.length <= 2 ? 38.0 : (label.length * 10.0 + 18.0);
      markers.add(
        Marker(
          width: width,
          height: 38,
          point: g.pos,
          alignment: Alignment.center,
          child: _dayPin(label: label, isLast: isLast),
        ),
      );
    }
    return markers;
  }

  List<LatLng> _evenlySpacedPositionsByDistance(List<LatLng> pts, int count) {
    if (pts.isEmpty) return const [];
    if (count <= 1 || pts.length == 1) return [pts.first];

    final segM = <double>[];
    double totalM = 0;
    for (var i = 0; i < pts.length - 1; i++) {
      final m = _distCalc.as(LengthUnit.Meter, pts[i], pts[i + 1]).abs();
      segM.add(m);
      totalM += m;
    }
    if (totalM <= 1) {
      return [pts.first, pts.last];
    }

    LatLng pointAt(double targetM) {
      var remaining = targetM.clamp(0, totalM);
      for (var i = 0; i < segM.length; i++) {
        final m = segM[i];
        if (remaining <= m || i == segM.length - 1) {
          final a = pts[i];
          final b = pts[i + 1];
          final t = m <= 0 ? 0.0 : (remaining / m).clamp(0.0, 1.0);
          return LatLng(
            a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t,
          );
        }
        remaining -= m;
      }
      return pts.last;
    }

    final out = <LatLng>[];
    for (var i = 0; i < count; i++) {
      final t = (count == 1) ? 0.0 : i / (count - 1);
      out.add(pointAt(totalM * t));
    }
    return out;
  }

  /// Builds the journey polyline shown on the map.
  ///
  /// Priority:
  ///   1. `routePath` (treks have a dense trail trace) → use it, with
  ///      Kathmandu prepended for context.
  ///   2. `dayLocations` (curated overnight stops for non-treks too) →
  ///      use them as the journey, with Kathmandu prepended if Day 1
  ///      isn't already near Kathmandu.
  ///   3. Single-day fallback → just the destination point.
  ///
  /// Multi-day trips always start from Kathmandu so the user sees how
  /// they get to the destination, not just a marker dropped into a
  /// remote village.
  static List<LatLng> _routePoints(NepalPlace place) {
    final dc = place.dayCount ?? 1;
    final isMultiDay = dc > 1 || place.type == 'Trek';

    bool nearKathmandu(LatLng p) {
      // ~3 km tolerance: if Day 1 is already Kathmandu, skip prepending.
      return _distCalc.as(LengthUnit.Meter, p, _kathmandu) < 3000;
    }

    final pts = <LatLng>[];

    if (place.routePath != null && place.routePath!.length >= 2) {
      final rp = place.routePath!.map((e) => LatLng(e.lat, e.lng)).toList();
      if (isMultiDay && !nearKathmandu(rp.first)) pts.add(_kathmandu);
      pts.addAll(rp);
      return pts;
    }

    final dl = place.dayLocations;
    if (dl != null && dl.isNotEmpty) {
      final dlPts = dl.map((e) => LatLng(e.lat, e.lng)).toList();
      if (isMultiDay && !nearKathmandu(dlPts.first)) pts.add(_kathmandu);
      pts.addAll(dlPts);
      return pts;
    }

    if (place.type == 'Trek' &&
        place.vehicleLat != null &&
        place.vehicleLng != null) {
      pts.add(_kathmandu);
      pts.add(LatLng(place.vehicleLat!, place.vehicleLng!));
      pts.add(LatLng(place.lat, place.lng));
      return pts;
    }

    final dest = LatLng(place.lat, place.lng);
    if (isMultiDay && !nearKathmandu(dest)) pts.add(_kathmandu);
    pts.add(dest);
    return pts;
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
      ..._dayMarkers(pts),
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
