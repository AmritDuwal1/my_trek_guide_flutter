import 'package:flutter/material.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class ApiOfflineBlock extends StatelessWidget {
  const ApiOfflineBlock({super.key, required this.onRetry, this.runHint});

  final VoidCallback onRetry;
  final String? runHint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: TravelColors.muted.withValues(alpha: 0.85)),
            const SizedBox(height: 18),
            Text(
              'We could not reach your tour API.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              runHint ??
                  'From the api folder:\npython manage.py runserver 0.0.0.0:8000',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TravelColors.muted,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
