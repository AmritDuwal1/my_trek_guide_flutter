import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tour_mobile/auth/auth_service.dart';
import 'package:tour_mobile/auth/guest_mode_store.dart';
import 'package:tour_mobile/screens/auth/sign_in_screen.dart';
import 'package:tour_mobile/screens/shell_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();

  String? _linkingUid;
  Future<void>? _linkFuture;
  String? _handledLinkErrorUid;
  Future<bool>? _guestFuture;

  void _ensureLinkFuture(User user) {
    if (_linkFuture != null && _linkingUid == user.uid) return;
    _linkingUid = user.uid;
    _handledLinkErrorUid = null;
    _linkFuture = _auth.linkSessionWithApi();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          _guestFuture ??= GuestModeStore.isEnabled();
          return FutureBuilder<bool>(
            future: _guestFuture,
            builder: (context, guestSnap) {
              if (guestSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (guestSnap.data == true) return const ShellScreen();
              return const SignInScreen();
            },
          );
        }

        _ensureLinkFuture(user);
        return FutureBuilder<void>(
          future: _linkFuture,
          builder: (context, linkSnap) {
            if (linkSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (linkSnap.hasError) {
              // Backend auth failed. Keep the user out of the app and show a clear error.
              if (_handledLinkErrorUid != user.uid) {
                _handledLinkErrorUid = user.uid;
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  final msg = linkSnap.error?.toString() ?? 'Could not sign in';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  await _auth.signOut();
                  if (!mounted) return;
                  // Reset so a new login attempt triggers a fresh link.
                  setState(() {
                    _linkingUid = null;
                    _linkFuture = null;
                    _guestFuture = null;
                  });
                });
              }
              return const SignInScreen();
            }

            return const ShellScreen();
          },
        );
      },
    );
  }
}

