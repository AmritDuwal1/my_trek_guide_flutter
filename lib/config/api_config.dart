import 'package:flutter/foundation.dart';

/// Base URL for the Python API (`api/`). Android emulator uses the host loopback alias.
String apiBaseUrl() {
  if (kIsWeb) return 'http://localhost:8000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}
