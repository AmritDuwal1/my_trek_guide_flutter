import 'package:flutter/foundation.dart';

/// Whether the app is pointing at the live (production) backend.
///
/// Override with:
/// `flutter run --dart-define=IS_LIVE=true`
// const bool isLive = bool.fromEnvironment('IS_LIVE', defaultValue: kReleaseMode);
const bool isLive = bool.fromEnvironment('IS_LIVE', defaultValue: false);

/// Base URL for the Python API (`api/`). Android emulator uses the host loopback alias.
String apiBaseUrl() {
  // Allow overriding without code changes:
  // flutter run --dart-define=API_BASE_URL=https://mytrekguide.amritduwal.com.np
  const defined = String.fromEnvironment('API_BASE_URL');
  if (defined.isNotEmpty) return defined;

  // Default (production) API.
  const prod = 'https://mytrekguide.amritduwal.com.np';

  if (isLive) return prod;

  // Non-live endpoints (local/dev).
  if (kIsWeb) return 'http://localhost:8000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://192.168.1.93:8000';
}
