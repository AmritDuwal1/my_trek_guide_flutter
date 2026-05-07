import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

/// Full-screen Google Map to choose a point; returns a human-readable label via reverse geocoding when possible.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  /// Parsed from profile text `"lat, lng"` or null → Kathmandu valley default.
  final LatLng? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _kDefault = LatLng(27.7172, 85.3240);

  late LatLng _pin = widget.initial ?? _kDefault;
  GoogleMapController? _mapController;
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final label = await _reverseGeocode(_pin.latitude, _pin.longitude);
      if (!mounted) return;
      Navigator.of(context).pop(label);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final list = await placemarkFromCoordinates(lat, lng);
      if (list.isEmpty) return _coordsOnly(lat, lng);
      final p = list.first;
      final parts = <String>[];
      void take(String? s) {
        final t = s?.trim();
        if (t != null && t.isNotEmpty && !parts.contains(t)) parts.add(t);
      }

      take(p.name);
      take(p.street);
      take(p.locality);
      take(p.subAdministrativeArea);
      take(p.administrativeArea);
      take(p.country);

      if (parts.isEmpty) return _coordsOnly(lat, lng);
      return parts.join(', ');
    } catch (_) {
      return _coordsOnly(lat, lng);
    }
  }

  String _coordsOnly(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  void _movePin(LatLng p) {
    setState(() => _pin = p);
    _mapController?.animateCamera(CameraUpdate.newLatLng(p));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.canvas,
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _busy ? null : _confirm,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Done'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _pin, zoom: 13),
            markers: {
              Marker(
                markerId: const MarkerId('profile_location'),
                position: _pin,
                draggable: true,
                onDragEnd: _movePin,
              ),
            },
            onTap: _movePin,
            onMapCreated: (c) => _mapController = c,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 28,
            child: Material(
              color: TravelColors.surface,
              elevation: 2,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  'Tap the map or drag the pin. Tap Done to fill your location.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
