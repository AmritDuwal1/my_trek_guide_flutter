import 'package:flutter/material.dart';
import 'package:tour_mobile/screens/favorites_screen.dart';
import 'package:tour_mobile/screens/home_screen.dart';
import 'package:tour_mobile/screens/map_screen.dart';
import 'package:tour_mobile/screens/menu_screen.dart';
import 'package:tour_mobile/screens/profile_screen.dart';
import 'package:tour_mobile/widgets/travel_shell_nav.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          MapScreen(),
          // MenuScreen(),
          FavoritesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: TravelShellNav(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}
