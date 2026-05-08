import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tour_mobile/profile/profile_service.dart';
import 'package:tour_mobile/services/support_service.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class HelpComplaintsScreen extends StatefulWidget {
  const HelpComplaintsScreen({super.key});

  @override
  State<HelpComplaintsScreen> createState() => _HelpComplaintsScreenState();
}

class _HelpComplaintsScreenState extends State<HelpComplaintsScreen> {
  final _support = SupportService();
  final _profile = ProfileService();

  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final user = FirebaseAuth.instance.currentUser;
    _email.text = user?.email ?? '';
    try {
      if (user != null) {
        final p = await _profile.get(user.uid);
        if (p != null) {
          if (_email.text.trim().isEmpty) _email.text = p.email;
          _phone.text = p.phone;
        }
      }
    } catch (_) {
      // ignore - offline
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter subject and message.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _support.submitComplaint(
        email: email,
        phone: phone,
        subject: subject,
        message: message,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent. Thank you!')),
      );
      _subject.clear();
      _message.clear();
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
      appBar: AppBar(title: const Text('Help & Complaints')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Send us your issue or complaint.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Send your issue or complaint to our support team.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              filled: true,
              fillColor: TravelColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TravelColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TravelColors.line),
              ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TravelColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TravelColors.line),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subject,
            decoration: InputDecoration(
              labelText: 'Subject',
              filled: true,
              fillColor: TravelColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TravelColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TravelColors.line),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            minLines: 6,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
              filled: true,
              fillColor: TravelColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TravelColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TravelColors.line),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : _send,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Send'),
            style: FilledButton.styleFrom(
              backgroundColor: TravelColors.navActive,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

