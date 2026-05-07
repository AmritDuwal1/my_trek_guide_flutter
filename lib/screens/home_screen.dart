import 'package:flutter/material.dart';
import 'package:tour_mobile/models/itinerary.dart';
import 'package:tour_mobile/notifications/notification_store.dart';
import 'package:tour_mobile/screens/itinerary_detail_screen.dart';
import 'package:tour_mobile/screens/notifications_screen.dart';
import 'package:tour_mobile/services/itinerary_service.dart';
import 'package:tour_mobile/theme/travel_theme.dart';
import 'package:tour_mobile/widgets/api_offline_block.dart';
import 'package:tour_mobile/widgets/browse_categories_row.dart';
import 'package:tour_mobile/widgets/city_glass_card.dart';
import 'package:tour_mobile/widgets/explore_cities_tabs.dart';
import 'package:tour_mobile/profile/user_session_store.dart';
import 'package:tour_mobile/widgets/home_user_greeting.dart';
import 'package:tour_mobile/widgets/travel_search_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ItineraryService();
  final _notifications = NotificationStore.instance;
  late Future<List<Itinerary>> _future;

  ExploreCitiesTab _exploreTab = ExploreCitiesTab.popular;
  String? _browseCategoryId;

  static const _browseCategories = [
    BrowseCategory(id: 'trek', label: 'Trekking', imageSeed: 'treknepal'),
    BrowseCategory(id: 'heritage', label: 'Heritage', imageSeed: 'templenp'),
    BrowseCategory(id: 'wild', label: 'Wildlife', imageSeed: 'rhino'),
    BrowseCategory(id: 'lake', label: 'Lakes', imageSeed: 'phewatal'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _service.fetchItineraries();
    _notifications.ensureLoaded();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchItineraries();
      UserSessionStore.bumpRevision();
    });
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

  bool _matchesBrowse(Itinerary it, String? browseId) {
    if (browseId == null) return true;
    final c = it.category;
    switch (browseId) {
      case 'trek':
        return c == 'Trek';
      case 'heritage':
        return c == 'Heritage';
      case 'wild':
        return c == 'National Park';
      case 'lake':
        return c == 'Lake';
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
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: TravelSearchField(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'Explore Cities',
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
                          'No cities match this filter.',
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
