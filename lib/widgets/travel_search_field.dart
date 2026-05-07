import 'package:flutter/material.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class TravelSearchField extends StatelessWidget {
  const TravelSearchField({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TravelColors.surface,
      borderRadius: BorderRadius.circular(22),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: TravelColors.muted.withValues(alpha: 0.9)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Discover places',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TravelColors.muted,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ),
              Icon(Icons.tune_rounded, color: TravelColors.muted.withValues(alpha: 0.75)),
            ],
          ),
        ),
      ),
    );
  }
}
