import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tour_mobile/models/itinerary.dart';
import 'package:tour_mobile/theme/cover_image.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

/// Large portrait city card with frosted bottom overlay (reference home screen).
class CityGlassCard extends StatelessWidget {
  const CityGlassCard({
    super.key,
    required this.itinerary,
    required this.onTap,
    this.width = 178,
    this.height = 246,
  });

  final Itinerary itinerary;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final rating = itinerary.rating.toStringAsFixed(1);
    final locationLine = (itinerary.province != null && itinerary.province!.isNotEmpty)
        ? '${itinerary.province} · ${itinerary.country}'
        : (itinerary.country.isNotEmpty ? itinerary.country : '—');
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Material(
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  itineraryCoverUrl(itinerary.id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: TravelColors.navActive.withValues(alpha: 0.25),
                    child: const Icon(Icons.landscape_rounded, size: 48, color: Colors.white70),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.88),
                            ],
                          ),
                          border: Border(
                            top: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itinerary.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: TravelColors.ink,
                                      height: 1.2,
                                      fontSize: 14,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: TravelColors.muted.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      locationLine,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            color: TravelColors.muted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  Icon(Icons.star_rounded, size: 17, color: Colors.amber.shade600),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: TravelColors.ink,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
