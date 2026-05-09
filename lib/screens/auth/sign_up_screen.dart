import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tour_mobile/auth/auth_service.dart';
import 'package:tour_mobile/profile/profile_service.dart';
import 'package:tour_mobile/profile/user_profile.dart';
import 'package:tour_mobile/profile/user_session_store.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _age = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();
  final _picker = ImagePicker();
  final _profiles = ProfileService();
  String _gender = 'prefer_not_to_say';
  File? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _age.dispose();
    _location.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (x == null) return;
    setState(() => _photo = File(x.path));
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
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
      appBar: AppBar(title: const Text('Sign up')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        children: [
          Text(
            'Create your account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Use email & password. You can also use Google/Apple on the sign-in screen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TravelColors.muted),
          ),
          const SizedBox(height: 18),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: TravelColors.line,
                  backgroundImage: _photo != null ? FileImage(_photo!) : null,
                  child: _photo == null ? const Icon(Icons.person_rounded, size: 40, color: TravelColors.muted) : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: TravelColors.navActive,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      onPressed: _busy ? null : _pickPhoto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fullName,
            decoration: InputDecoration(
              labelText: 'Full name',
              filled: true,
              fillColor: TravelColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
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
                onChanged: _busy ? null : (v) => setState(() => _gender = v ?? 'prefer_not_to_say'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Age',
              filled: true,
              fillColor: TravelColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: InputDecoration(
              labelText: 'Location',
              filled: true,
              fillColor: TravelColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone number',
              filled: true,
              fillColor: TravelColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TravelColors.line)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              filled: true,
              fillColor: TravelColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: TravelColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: TravelColors.line)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'At least 6 characters (Firebase default).',
              filled: true,
              fillColor: TravelColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: TravelColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: TravelColors.line)),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final cred = await _auth.signUpWithEmail(email: _email.text.trim(), password: _password.text);
                      final user = cred.user ?? FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      String photoUrl = '';
                      if (_photo != null) {
                        photoUrl = await _profiles.uploadProfilePhoto(file: _photo!);
                      }

                      final now = DateTime.now().millisecondsSinceEpoch;
                      final profile = UserProfile(
                        uid: user.uid,
                        fullName: _fullName.text.trim(),
                        gender: _gender,
                        age: int.tryParse(_age.text.trim()) ?? 0,
                        location: _location.text.trim(),
                        homeLat: null,
                        homeLng: null,
                        email: user.email ?? _email.text.trim(),
                        phone: _phone.text.trim(),
                        photoUrl: photoUrl,
                        createdAtMs: now,
                        updatedAtMs: now,
                      );
                      await _profiles.upsert(profile);
                      await UserSessionStore.mergeFromProfile(
                        uid: user.uid,
                        fullName: profile.fullName,
                        photoUrl: photoUrl,
                      );
                    }),
            style: FilledButton.styleFrom(
              backgroundColor: TravelColors.navActive,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(_busy ? 'Please wait…' : 'Create account'),
          ),
        ],
      ),
    );
  }
}

