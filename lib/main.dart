import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tour_mobile/firebase_options.dart';
import 'package:tour_mobile/push/push_notification_service.dart';
import 'package:tour_mobile/screens/auth/auth_gate.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushNotificationService.instance.init();
  runApp(const TourApp());
}

class TourApp extends StatelessWidget {
  const TourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tour',
      debugShowCheckedModeBanner: false,
      theme: buildTravelTheme(),
      home: const AuthGate(),
    );
  }
}
