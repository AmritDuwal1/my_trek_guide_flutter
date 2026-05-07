import 'package:flutter/material.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

enum ExploreCitiesTab {
  all,
  popular,
  recommended,
  mostViewed,
}

extension ExploreCitiesTabLabel on ExploreCitiesTab {
  String get label => switch (this) {
        ExploreCitiesTab.all => 'All',
        ExploreCitiesTab.popular => 'Popular',
        ExploreCitiesTab.recommended => 'Recommended',
        ExploreCitiesTab.mostViewed => 'Most Viewed',
      };
}

class ExploreCitiesTextTabs extends StatelessWidget {
  const ExploreCitiesTextTabs({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ExploreCitiesTab selected;
  final ValueChanged<ExploreCitiesTab> onSelect;

  @override
  Widget build(BuildContext context) {
    const tabs = ExploreCitiesTab.values;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 22),
        itemBuilder: (context, i) {
          final tab = tabs[i];
          final active = tab == selected;
          return GestureDetector(
            onTap: () => onSelect(tab),
            behavior: HitTestBehavior.opaque,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tab.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? TravelColors.ink : TravelColors.muted,
                      fontSize: 15,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
