import 'package:flutter/material.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TravelColors.canvas,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 20, 22, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.35,
              ),
              delegate: SliverChildListDelegate([
                _MenuTile(icon: Icons.list_alt_rounded, label: 'All places', onTap: () => _openExplore(context)),
                _MenuTile(icon: Icons.map_rounded, label: 'Map', onTap: () => _openMap(context)),
                _MenuTile(icon: Icons.hiking_rounded, label: 'Treks', onTap: () {}),
                _MenuTile(icon: Icons.account_balance_rounded, label: 'Heritage', onTap: () {}),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

void _openExplore(BuildContext context) {
  // Explore list already exists as the "All places" experience via ExploreScreen in earlier build.
  // For now, keep this as a placeholder route hook if needed later.
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Open Explore: use the Nepal list tab in the app')),
  );
}

void _openMap(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Open Map: use the Map tab (compass icon)')),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TravelColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: TravelColors.navActive),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
