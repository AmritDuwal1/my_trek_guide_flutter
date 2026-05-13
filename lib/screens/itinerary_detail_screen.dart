import 'package:flutter/material.dart';
import 'package:tour_mobile/models/itinerary.dart';
import 'package:tour_mobile/auth/auth_required.dart';
import 'package:tour_mobile/services/favorites_service.dart';
import 'package:tour_mobile/services/itinerary_service.dart';
import 'package:tour_mobile/theme/cover_image.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:tour_mobile/widgets/network_image_fallback.dart';

class ItineraryDetailScreen extends StatefulWidget {
  const ItineraryDetailScreen({super.key, required this.itineraryId});

  final String itineraryId;

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  final _service = ItineraryService();
  final _favorites = FavoritesService();
  late Future<Itinerary> _future;
  bool _favorite = false;
  bool _favBusy = true;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchItinerary(widget.itineraryId);
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    try {
      final v = await _favorites.isFavorite(widget.itineraryId);
      if (mounted) setState(() => _favorite = v);
    } catch (_) {
      // Ignore favorite load errors (offline / unauthorized) and keep UI usable.
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favBusy) return;
    final ok = await ensureSignedIn(context, message: 'Sign in to save favorites.');
    if (!ok) return;
    setState(() {
      _favBusy = true;
      _favorite = !_favorite;
    });
    try {
      final saved = await _favorites.setFavorite(widget.itineraryId, _favorite);
      if (mounted) setState(() => _favorite = saved);
    } catch (e) {
      if (!mounted) return;
      // Revert on failure.
      setState(() => _favorite = !_favorite);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.canvas,
      body: FutureBuilder<Itinerary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _ErrorBody(message: snapshot.error?.toString() ?? 'Failed to load');
          }
          final it = snapshot.data!;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: TravelColors.primary,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: _favorite ? 'Remove favorite' : 'Add to favorites',
                        icon: Icon(
                          _favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _favorite ? Colors.redAccent.shade100 : Colors.white,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkImageWithFallback(
                        urls: itineraryCoverUrls(
                          it.id,
                          preferred: [
                            if (it.imageUrl != null) it.imageUrl!,
                            ...it.imageUrls,
                          ],
                        ),
                        fit: BoxFit.cover,
                        placeholder: ColoredBox(
                          color: TravelColors.primary.withValues(alpha: 0.5),
                          child: const Icon(Icons.landscape_rounded, size: 80, color: Colors.white54),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: Material(
                    color: TravelColors.canvas,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  it.title,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (it.province != null && it.province!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: TravelColors.line,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      it.province!,
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: TravelColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  it.category,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: TravelColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            it.summary,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: TravelColors.muted,
                                  height: 1.45,
                                ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Itinerary',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          ...it.days.map((d) => _DayCard(day: d)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final DayPlan day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: TravelColors.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TravelColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: TravelColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${day.day}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: TravelColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...day.stops.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.time != null) ...[
                        SizedBox(
                          width: 48,
                          child: Text(
                            s.time!,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: TravelColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ] else
                        const SizedBox(width: 48),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (s.notes != null && s.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                s.notes!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: TravelColors.muted,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
