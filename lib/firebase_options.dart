// Generated-like file (manual) to fix [core/not-initialized].
// Source values come from:
// - android/app/google-services.json
// - ios/Runner/GoogleService-Info.plist

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase options not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.macOS:
        // not configured
        throw UnsupportedError('macOS Firebase options not configured.');
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase options not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBZ3_JMWRiKdf2-rA3pnCIuGQtZG4CyfuA',
    appId: '1:1053627493780:android:c661c3e987ea1f048e3381',
    messagingSenderId: '1053627493780',
    projectId: 'my-trek-guide-253c2',
    storageBucket: 'my-trek-guide-253c2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDODE3ZJkS8jkYVdcFPmT12eCFVJeCiNXM',
    appId: '1:1053627493780:ios:32ed31646787305d8e3381',
    messagingSenderId: '1053627493780',
    projectId: 'my-trek-guide-253c2',
    storageBucket: 'my-trek-guide-253c2.firebasestorage.app',
    iosBundleId: 'com.mytrekguide.app',
  );
}

