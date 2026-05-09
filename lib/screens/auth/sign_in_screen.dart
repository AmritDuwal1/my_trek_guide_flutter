import 'package:flutter/material.dart';
import 'package:tour_mobile/auth/auth_service.dart';
import 'package:tour_mobile/auth/guest_mode_store.dart';
import 'package:tour_mobile/screens/shell_screen.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
      // If this screen was opened as a route (e.g. from an auth-required prompt),
      // close it after successful login so the user returns to the app.
      if (mounted) {
        await Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skipLogin() async {
    setState(() => _busy = true);
    try {
      await GuestModeStore.setEnabled(true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const ShellScreen()));
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          children: [
            Text('Welcome', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Sign in to save favorites and sync your trips.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TravelColors.muted),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _skipLogin,
                child: const Text('Skip for now'),
              ),
            ),
            _Field(label: 'Email', controller: _email, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _Field(label: 'Password', controller: _password, obscure: true),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await _auth.signInWithEmail(email: _email.text.trim(), password: _password.text);
                      }),
              style: FilledButton.styleFrom(
                backgroundColor: TravelColors.navActive,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_busy ? 'Please wait…' : 'Sign in'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: TravelColors.line.withValues(alpha: 0.9))),
                const SizedBox(width: 12),
                Text('or', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TravelColors.muted)),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: TravelColors.line.withValues(alpha: 0.9))),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(() async => _auth.signInWithGoogle()),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TravelColors.ink,
                side: BorderSide(color: TravelColors.line.withValues(alpha: 0.9)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: TravelColors.surface,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(() async => _auth.signInWithApple()),
              icon: const Icon(Icons.apple_rounded),
              label: const Text('Continue with Apple'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TravelColors.ink,
                side: BorderSide(color: TravelColors.line.withValues(alpha: 0.9)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: TravelColors.surface,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
                      );
                    },
              child: const Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboard,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: TravelColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: TravelColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: TravelColors.line)),
      ),
    );
  }
}

