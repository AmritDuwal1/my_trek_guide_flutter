import 'package:flutter/material.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

/// Five-icon bar from reference: Home, Explore, grid menu, Favorites, Profile.
class TravelShellNav extends StatelessWidget {
  const TravelShellNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <IconData>[
      Icons.home_rounded,
      Icons.explore_outlined,
      Icons.grid_view_rounded,
      Icons.favorite_border_rounded,
      Icons.person_outline_rounded,
    ];

    return Material(
      color: TravelColors.surface,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final sel = i == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i],
                          size: 28,
                          color: sel ? TravelColors.navActive : TravelColors.muted,
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 5,
                          width: 5,
                          decoration: BoxDecoration(
                            color: sel ? TravelColors.navActive : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
