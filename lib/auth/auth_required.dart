import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tour_mobile/screens/auth/sign_in_screen.dart';

bool _authDialogOpen = false;

class AuthRequiredException implements Exception {
  const AuthRequiredException([this.message = 'Sign in required']);
  final String message;
  @override
  String toString() => message;
}

Future<bool> ensureSignedIn(BuildContext context, {String? message}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) return true;
  if (_authDialogOpen) return false;
  _authDialogOpen = true;

  try {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign in required'),
        content: Text(message ?? 'Please sign in to continue.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sign in')),
        ],
      ),
    );

    if (go == true && context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SignInScreen()));
    }
    return FirebaseAuth.instance.currentUser != null;
  } finally {
    _authDialogOpen = false;
  }
}

