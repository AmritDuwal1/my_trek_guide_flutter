import 'package:flutter/material.dart';
import 'package:tour_mobile/models/itinerary.dart';
import 'package:tour_mobile/screens/itinerary_detail_screen.dart';
import 'package:tour_mobile/services/favorites_service.dart';
import 'package:tour_mobile/widgets/api_offline_block.dart';
import 'package:tour_mobile/widgets/city_glass_card.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _service = FavoritesService();
  late Future<List<Itinerary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchFavorites();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchFavorites();
    });
    await _future;
  }

  void _open(Itinerary it) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ItineraryDetailScreen(itineraryId: it.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TravelColors.canvas,
      child: SafeArea(
        child: FutureBuilder<List<Itinerary>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: TravelColors.navActive));
            }
            if (snapshot.hasError) {
              return ApiOfflineBlock(onRetry: _reload);
            }
            final favs = snapshot.data ?? const <Itinerary>[];
            if (favs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border_rounded, size: 64, color: TravelColors.muted.withValues(alpha: 0.5)),
                      const SizedBox(height: 20),
                      Text(
                        'Favorites',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add favorites from itinerary pages and they will show here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: TravelColors.muted,
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: TravelColors.navActive,
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                children: [
                  Text(
                    'Favorites',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  ...favs.map(
                    (it) => CityGlassCard(
                      itinerary: it,
                      width: double.infinity,
                      height: 170,
                      onTap: () => _open(it),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
