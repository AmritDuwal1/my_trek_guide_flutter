import 'package:flutter/material.dart';
import 'package:tour_mobile/models/itinerary.dart';
import 'package:tour_mobile/notifications/notification_store.dart';
import 'package:tour_mobile/screens/country_picker_screen.dart';
import 'package:tour_mobile/screens/itinerary_detail_screen.dart';
import 'package:tour_mobile/screens/notifications_screen.dart';
import 'package:tour_mobile/services/itinerary_service.dart';
import 'package:tour_mobile/stores/country_store.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:tour_mobile/widgets/api_offline_block.dart';
import 'package:tour_mobile/widgets/browse_categories_row.dart';
import 'package:tour_mobile/widgets/city_glass_card.dart';
import 'package:tour_mobile/widgets/explore_cities_tabs.dart';
import 'package:tour_mobile/profile/user_session_store.dart';
import 'package:tour_mobile/screens/identify/identify_plants_animals_screen.dart';
import 'package:tour_mobile/widgets/home_user_greeting.dart';
import 'package:tour_mobile/screens/place_search_screen.dart';
import 'package:tour_mobile/widgets/travel_search_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ItineraryService();
  final _notifications = NotificationStore.instance;
  final _countryStore = CountryStore.instance;
  late Future<List<Itinerary>> _future;

  ExploreCitiesTab _exploreTab = ExploreCitiesTab.popular;
  String? _browseCategoryId;

  static const _browseCategories = [
    BrowseCategory(id: 'trek', label: 'Trekking', imageSeed: 'treknepal'),
    BrowseCategory(id: 'heritage', label: 'Heritage', imageSeed: 'templenp'),
    BrowseCategory(id: 'wild', label: 'Wildlife', imageSeed: 'rhino'),
    BrowseCategory(id: 'lake', label: 'Lakes', imageSeed: 'phewatal'),
    BrowseCategory(id: 'beach', label: 'Beaches', imageSeed: 'beach'),
    BrowseCategory(id: 'city', label: 'Cities', imageSeed: 'city'),
  ];

  @override
  void initState() {
    super.initState();
    _loadForCurrentCountry();
    _notifications.ensureLoaded();
    _countryStore.addListener(_onCountryChanged);
  }

  @override
  void dispose() {
    _countryStore.removeListener(_onCountryChanged);
    super.dispose();
  }

  void _onCountryChanged() {
    _loadForCurrentCountry();
  }

  void _loadForCurrentCountry() {
    setState(() {
      _future = _service.fetchItineraries(
        countryCode: _countryStore.selected.code,
      );
    });
  }

  Future<void> _reload() async {
    _loadForCurrentCountry();
    UserSessionStore.bumpRevision();
    await _future;
  }

  void _open(Itinerary it) {
    _notifications.add(title: 'Viewed place', body: it.title);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ItineraryDetailScreen(itineraryId: it.id),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openCountryPicker() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const CountryPickerScreen()),
    );
  }

  bool _matchesBrowse(Itinerary it, String? browseId) {
    if (browseId == null) return true;
    final c = it.category.toLowerCase();
    switch (browseId) {
      case 'trek':
        return c == 'trek';
      case 'heritage':
        return c == 'heritage';
      case 'wild':
        return c == 'national park';
      case 'lake':
        return c == 'lake';
      case 'beach':
        return c == 'beach' || c == 'island';
      case 'city':
        return c == 'city';
      default:
        return true;
    }
  }

  List<Itinerary> _applyExploreSort(List<Itinerary> list, ExploreCitiesTab tab) {
    final copy = [...list];
    switch (tab) {
      case ExploreCitiesTab.all:
        return copy;
      case ExploreCitiesTab.popular:
        copy.sort((a, b) => b.rating.compareTo(a.rating));
        return copy;
      case ExploreCitiesTab.recommended:
        copy.sort((a, b) => a.title.compareTo(b.title));
        return copy;
      case ExploreCitiesTab.mostViewed:
        return copy.reversed.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Itinerary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: TravelColors.canvas,
            child: Center(
              child: CircularProgressIndicator(color: TravelColors.navActive),
            ),
          );
        }
        if (snapshot.hasError) {
          return ColoredBox(
            color: TravelColors.canvas,
            child: ApiOfflineBlock(onRetry: _reload),
          );
        }

        final all = snapshot.data ?? const <Itinerary>[];
        if (all.isEmpty) {
          return ColoredBox(
            color: TravelColors.canvas,
            child: Center(
              child: Text('No trips yet.', style: Theme.of(context).textTheme.bodyLarge),
            ),
          );
        }

        final filtered = all.where((e) => _matchesBrowse(e, _browseCategoryId)).toList();
        final cities = _applyExploreSort(filtered, _exploreTab);

        return RefreshIndicator(
          color: TravelColors.navActive,
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 8, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeUserGreeting(
                        notificationSlot: AnimatedBuilder(
                          animation: _notifications,
                          builder: (context, _) {
                            final unread = _notifications.unreadCount;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  onPressed: _openNotifications,
                                  tooltip: 'Notifications',
                                  icon: const Icon(Icons.notifications_none_rounded),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: TravelColors.navActive,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Where do you want to go?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              height: 1.2,
                              color: TravelColors.ink,
                            ),
                      ),
                      const SizedBox(height: 14),
                      // ── Country selector chip ──────────────────────────
                      ListenableBuilder(
                        listenable: _countryStore,
                        builder: (context, _) => _CountryChip(
                          country: _countryStore.selected.name,
                          emoji: _countryStore.selected.emoji,
                          onTap: _openCountryPicker,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: TravelSearchField(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const PlaceSearchScreen()),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Material(
                    color: TravelColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.06),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const IdentifyPlantsAnimalsScreen()),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: TravelColors.navActive.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pets_rounded, color: TravelColors.navActive),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Identify plants & animals',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to take a photo and identify.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
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
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'Explore Places',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: ExploreCitiesTextTabs(
                  selected: _exploreTab,
                  onSelect: (t) => setState(() => _exploreTab = t),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: cities.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                        child: Text(
                          'No places match this filter.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TravelColors.muted),
                        ),
                      )
                    : SizedBox(
                        height: 246,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 22),
                          itemCount: cities.length,
                          itemBuilder: (context, i) {
                            final it = cities[i];
                            return CityGlassCard(
                              itinerary: it,
                              onTap: () => _open(it),
                            );
                          },
                        ),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(foregroundColor: TravelColors.muted),
                        child: const Text('See all >'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: BrowseCategoriesRow(
                  categories: _browseCategories,
                  selectedId: _browseCategoryId,
                  onSelect: (id) => setState(() => _browseCategoryId = id),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

// ── Country chip ─────────────────────────────────────────────────────────────

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.country,
    required this.emoji,
    required this.onTap,
  });

  final String country;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: TravelColors.navActive.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: TravelColors.navActive.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              country,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TravelColors.navActive,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded,
                size: 16, color: TravelColors.navActive),
          ],
        ),
      ),
    );
  }
}
