import 'package:flutter/material.dart';
import 'package:tour_mobile/models/nepal_place.dart';
import 'package:tour_mobile/screens/itinerary_detail_screen.dart';
import 'package:tour_mobile/services/itinerary_service.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:tour_mobile/widgets/api_offline_block.dart';

/// Alphabetic list of all Nepal travel places from the API, grouped by province.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.typeFilter});

  /// Optional exact place type filter (e.g. `Trek`, `Heritage`).
  final String? typeFilter;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _service = ItineraryService();
  late Future<List<NepalPlace>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchNepalPlaces();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchNepalPlaces();
    });
    await _future;
  }

  Map<String, List<NepalPlace>> _groupByProvince(List<NepalPlace> places) {
    final map = <String, List<NepalPlace>>{};
    for (final p in places) {
      map.putIfAbsent(p.province, () => []).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TravelColors.canvas,
      child: FutureBuilder<List<NepalPlace>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: TravelColors.navActive));
          }
          if (snapshot.hasError) {
            return ApiOfflineBlock(onRetry: _reload);
          }
          final all = snapshot.data ?? const <NepalPlace>[];
          final tf = widget.typeFilter?.trim();
          final places = (tf == null || tf.isEmpty) ? all : all.where((p) => p.type == tf).toList();
          if (places.isEmpty) {
            return Center(
              child: Text(
                tf == null || tf.isEmpty ? 'No places loaded.' : 'No places found for "$tf".',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            );
          }
          final grouped = _groupByProvince(places);
          final provinces = grouped.keys.toList()..sort();

          return RefreshIndicator(
            color: TravelColors.navActive,
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tf == null || tf.isEmpty ? 'Nepal' : tf,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${places.length} travel places · tap for details',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final prov in provinces) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        prov,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: TravelColors.navActive,
                            ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = grouped[prov]![i];
                        return _PlaceTile(
                          place: p,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ItineraryDetailScreen(itineraryId: p.id),
                              ),
                            );
                          },
                        );
                      },
                      childCount: grouped[prov]!.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});

  final NepalPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: Material(
        color: TravelColors.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: TravelColors.navActive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconForType(place.type), size: 22, color: TravelColors.navActive),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.type,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: TravelColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TravelColors.muted,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: TravelColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'Trek':
      return Icons.hiking_rounded;
    case 'Heritage':
      return Icons.account_balance_rounded;
    case 'National Park':
      return Icons.forest_rounded;
    case 'Lake':
      return Icons.water_rounded;
    case 'Pilgrimage':
      return Icons.temple_hindu_rounded;
    case 'City':
      return Icons.location_city_rounded;
    case 'Viewpoint':
      return Icons.landscape_rounded;
    case 'Hill Station':
      return Icons.cottage_rounded;
    case 'Adventure':
      return Icons.kayaking_rounded;
    default:
      return Icons.place_rounded;
  }
}
