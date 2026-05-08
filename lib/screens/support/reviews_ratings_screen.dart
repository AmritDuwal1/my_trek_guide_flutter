import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewsRatingsScreen extends StatelessWidget {
  const ReviewsRatingsScreen({super.key});

  Future<void> _openStore(BuildContext context) async {
    // TODO: replace with your real store URLs before release.
    final Uri uri = kIsWeb
        ? Uri.parse('https://example.com')
        : (defaultTargetPlatform == TargetPlatform.iOS)
            ? Uri.parse('https://apps.apple.com/app/id0000000000?action=write-review')
            : Uri.parse('https://play.google.com/store/apps/details?id=com.tour.tour_mobile&reviewId=0');

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the store page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.canvas,
      appBar: AppBar(title: const Text('Reviews & Ratings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Enjoying the app?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Please leave a rating and review. It helps us improve and reach more travelers.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openStore(context),
            icon: const Icon(Icons.star_rate_rounded),
            label: const Text('Rate this app'),
            style: FilledButton.styleFrom(
              backgroundColor: TravelColors.navActive,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Note: store links need your real App Store / Play Store IDs before release.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: TravelColors.muted),
          ),
        ],
      ),
    );
  }
}

