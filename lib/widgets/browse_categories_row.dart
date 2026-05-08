import 'package:flutter/material.dart';
import 'package:tour_mobile/theme/cover_image.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class BrowseCategory {
  const BrowseCategory({required this.id, required this.label, required this.imageSeed});

  final String id;
  final String label;
  final String imageSeed;
}

/// Reference: small square thumbs + label; selected = white rounded shell + shadow.
class BrowseCategoriesRow extends StatelessWidget {
  const BrowseCategoriesRow({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<BrowseCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = categories[i];
          final selected = c.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(selected ? null : c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              decoration: BoxDecoration(
                color: selected ? TravelColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      categoryThumbUrl(c.imageSeed),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: TravelColors.line,
                        child: const Icon(Icons.image_outlined, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? TravelColors.ink : TravelColors.muted,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
