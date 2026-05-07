import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tour_mobile/profile/profile_service.dart';
import 'package:tour_mobile/profile/user_profile.dart';
import 'package:tour_mobile/profile/user_session_store.dart';
import 'package:tour_mobile/screens/profile/location_picker_screen.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _service = ProfileService();
  final _picker = ImagePicker();

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();

  String _gender = 'prefer_not_to_say';
  String _photoUrl = '';
  File? _newPhoto;
  double? _homeLat;
  double? _homeLng;

  bool _busy = true;

  User get _user => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _service.get(_user.uid);
    final now = DateTime.now().millisecondsSinceEpoch;
    final profile = p ??
        UserProfile(
          uid: _user.uid,
          fullName: _user.displayName ?? '',
          gender: 'prefer_not_to_say',
          age: 0,
          location: '',
          homeLat: null,
          homeLng: null,
          email: _user.email ?? '',
          phone: '',
          photoUrl: _user.photoURL ?? '',
          createdAtMs: now,
          updatedAtMs: now,
        );

    _name.text = profile.fullName;
    _age.text = profile.age == 0 ? '' : '${profile.age}';
    _location.text = profile.location;
    _phone.text = profile.phone;
    _gender = profile.gender;
    _photoUrl = profile.photoUrl;
    _homeLat = profile.homeLat;
    _homeLng = profile.homeLng;

    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _location.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (x == null) return;
    setState(() => _newPhoto = File(x.path));
  }

  LatLng? _latLngFromLocationText(String raw) {
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  Future<void> _pickLocationOnMap() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map picker is not configured for web yet.')),
      );
      return;
    }
    final initial = _latLngFromLocationText(_location.text.trim());
    final label = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => LocationPickerScreen(initial: initial),
      ),
    );
    if (label != null && mounted) {
      final coords = _latLngFromLocationText(label);
      setState(() {
        _location.text = label;
        _homeLat = coords?.latitude ?? _homeLat;
        _homeLng = coords?.longitude ?? _homeLng;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      var url = _photoUrl;
      if (_newPhoto != null) {
        url = await _service.uploadProfilePhoto(uid: _user.uid, file: _newPhoto!);
      }

      final age = int.tryParse(_age.text.trim()) ?? 0;
      final profile = UserProfile(
        uid: _user.uid,
        fullName: _name.text.trim(),
        gender: _gender,
        age: age,
        location: _location.text.trim(),
        homeLat: _homeLat,
        homeLng: _homeLng,
        email: _user.email ?? '',
        phone: _phone.text.trim(),
        photoUrl: url,
        createdAtMs: now, // merge will keep existing if already set
        updatedAtMs: now,
      );

      await _service.upsert(profile);
      await UserSessionStore.mergeFromProfile(
        uid: profile.uid,
        fullName: profile.fullName,
        photoUrl: url,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.canvas,
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator(color: TravelColors.navActive))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: TravelColors.line,
                        backgroundImage: _newPhoto != null
                            ? FileImage(_newPhoto!)
                            : (_photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null) as ImageProvider<Object>?,
                        child: (_newPhoto == null && _photoUrl.isEmpty)
                            ? const Icon(Icons.person_rounded, size: 44, color: TravelColors.muted)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: TravelColors.navActive,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            onPressed: _pickPhoto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _textField(label: 'Full name', controller: _name),
                const SizedBox(height: 12),
                _genderField(context),
                const SizedBox(height: 12),
                _textField(
                  label: 'Age',
                  controller: _age,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _locationField(context),
                const SizedBox(height: 12),
                _textField(
                  label: 'Phone number',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                Text(
                  'Email: ${_user.email ?? ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                ),
              ],
            ),
    );
  }

  Widget _locationField(BuildContext context) {
    return TextField(
      controller: _location,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Location',
        filled: true,
        fillColor: TravelColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
        suffixIcon: IconButton(
          tooltip: 'Pick on map',
          icon: const Icon(Icons.map_rounded, color: TravelColors.navActive),
          onPressed: _busy ? null : _pickLocationOnMap,
        ),
      ),
    );
  }

  Widget _genderField(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Gender',
        filled: true,
        fillColor: TravelColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
            DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
          ],
          onChanged: (v) => setState(() => _gender = v ?? 'prefer_not_to_say'),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: TravelColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
      ),
    );
  }
}

