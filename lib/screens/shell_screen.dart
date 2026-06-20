import 'package:flutter/material.dart';
import 'package:tour_mobile/models/app_country.dart';
import 'package:tour_mobile/screens/country_picker_screen.dart';
import 'package:tour_mobile/screens/favorites_screen.dart';
import 'package:tour_mobile/screens/home_screen.dart';
import 'package:tour_mobile/screens/map_screen.dart';
import 'package:tour_mobile/screens/profile_screen.dart';
import 'package:tour_mobile/stores/country_store.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:tour_mobile/widgets/travel_shell_nav.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;
  final _store = CountryStore.instance;

  @override
  void initState() {
    super.initState();
    // Request location permission and detect country after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectAndPrompt());
  }

  Future<void> _detectAndPrompt() async {
    final detected = await _store.detectCountry();
    if (!mounted) return;
    if (detected != null && detected != _store.selected) {
      _showDetectedCountrySheet(detected);
    }
  }

  void _showDetectedCountrySheet(AppCountry detected) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetectedCountrySheet(
        detected: detected,
        onAccept: () {
          _store.select(detected);
          Navigator.pop(context);
        },
        onChooseAnother: () {
          Navigator.pop(context);
          _openCountryPicker(detectedCountry: detected);
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _openCountryPicker({AppCountry? detectedCountry}) async {
    await Navigator.of(context).push<AppCountry>(
      MaterialPageRoute(
        builder: (_) => CountryPickerScreen(detectedCountry: detectedCountry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: IndexedStack(
            index: _tab,
            children: const [
              HomeScreen(),
              MapScreen(),
              FavoritesScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: TravelShellNav(
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        );
      },
    );
  }
}

// ── Detected-country bottom sheet ────────────────────────────────────────────

class _DetectedCountrySheet extends StatelessWidget {
  const _DetectedCountrySheet({
    required this.detected,
    required this.onAccept,
    required this.onChooseAnother,
    required this.onDismiss,
  });

  final AppCountry detected;
  final VoidCallback onAccept;
  final VoidCallback onChooseAnother;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: TravelColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: TravelColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Flag + name
          Row(
            children: [
              Text(detected.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're in ${detected.name}",
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Show places in ${detected.name}?',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: TravelColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Accept button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: TravelColors.navActive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Yes, explore ${detected.name}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Choose another
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onChooseAnother,
              style: OutlinedButton.styleFrom(
                foregroundColor: TravelColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: TravelColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Choose another country',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(foregroundColor: TravelColors.muted),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
