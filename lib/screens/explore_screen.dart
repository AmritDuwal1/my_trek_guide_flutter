import 'package:flutter/material.dart';
import 'package:tour_mobile/models/world_place.dart';
import 'package:tour_mobile/screens/itinerary_detail_screen.dart';
import 'package:tour_mobile/services/place_service.dart';
import 'package:tour_mobile/stores/country_store.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:tour_mobile/widgets/api_offline_block.dart';

/// List of travel places for the selected country, grouped by region.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.typeFilter, this.countryCode});

  /// Optional place-type filter (e.g. `Trek`, `Heritage`).
  final String? typeFilter;

  /// Override country code. Falls back to [CountryStore.selected].
  final String? countryCode;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _service = PlaceService();
  final _countryStore = CountryStore.instance;
  late Future<List<WorldPlace>> _future;
  late String _activeCode;

  @override
  void initState() {
    super.initState();
    _activeCode = widget.countryCode ?? _countryStore.selected.code;
    _future = _service.fetchWorldPlaces(_activeCode);
    _countryStore.addListener(_onCountryChanged);
  }

  @override
  void dispose() {
    _countryStore.removeListener(_onCountryChanged);
    super.dispose();
  }

  void _onCountryChanged() {
    if (widget.countryCode != null) return; // pinned to explicit code
    final newCode = _countryStore.selected.code;
    if (newCode == _activeCode) return;
    setState(() {
      _activeCode = newCode;
      _future = _service.fetchWorldPlaces(_activeCode);
    });
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchWorldPlaces(_activeCode);
    });
    await _future;
  }

  Map<String, List<WorldPlace>> _groupByRegion(List<WorldPlace> places) {
    final map = <String, List<WorldPlace>>{};
    for (final p in places) {
      map.putIfAbsent(p.region, () => []).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }

  String get _countryName {
    try {
      return _countryStore.allCountries
          .firstWhere((c) => c.code == _activeCode)
          .name;
    } catch (_) {
      return _activeCode;
    }
  }

  String get _countryEmoji {
    try {
      return _countryStore.allCountries
          .firstWhere((c) => c.code == _activeCode)
          .emoji;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TravelColors.canvas,
      child: FutureBuilder<List<WorldPlace>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: TravelColors.navActive));
          }
          if (snapshot.hasError) {
            return ApiOfflineBlock(onRetry: _reload);
          }
          final all = snapshot.data ?? const <WorldPlace>[];
          final tf = widget.typeFilter?.trim();
          final places = (tf == null || tf.isEmpty)
              ? all
              : all.where((p) => p.type == tf).toList();

          if (places.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _countryEmoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tf == null || tf.isEmpty
                          ? 'No places loaded for $_countryName.'
                          : 'No places found for "$tf" in $_countryName.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final grouped = _groupByRegion(places);
          final regions = grouped.keys.toList()..sort();

          return RefreshIndicator(
            color: TravelColors.navActive,
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      20, MediaQuery.paddingOf(context).top + 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_countryEmoji.isNotEmpty)
                              Text(_countryEmoji,
                                  style: const TextStyle(fontSize: 28)),
                            if (_countryEmoji.isNotEmpty)
                              const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tf == null || tf.isEmpty
                                    ? _countryName
                                    : tf,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${places.length} travel places · tap for details',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: TravelColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final region in regions) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        region,
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
                        final p = grouped[region]![i];
                        return _PlaceTile(
                          place: p,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ItineraryDetailScreen(itineraryId: p.id),
                              ),
                            );
                          },
                        );
                      },
                      childCount: grouped[region]!.length,
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

  final WorldPlace place;
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
                  child: Icon(_iconForType(place.type),
                      size: 22, color: TravelColors.navActive),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
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
    case 'Beach':
      return Icons.beach_access_rounded;
    case 'Island':
      return Icons.sailing_rounded;
    default:
      return Icons.place_rounded;
  }
}
