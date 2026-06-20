import 'package:flutter/material.dart';
import 'package:tour_mobile/models/app_country.dart';
import 'package:tour_mobile/stores/country_store.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

/// Full-screen country picker with search bar and continent grouping.
class CountryPickerScreen extends StatefulWidget {
  const CountryPickerScreen({super.key, this.detectedCountry});

  /// If set, a "detected" chip is shown at the top.
  final AppCountry? detectedCountry;

  @override
  State<CountryPickerScreen> createState() => _CountryPickerScreenState();
}

class _CountryPickerScreenState extends State<CountryPickerScreen> {
  final _store = CountryStore.instance;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppCountry> get _filtered {
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return _store.allCountries;
    return _store.allCountries
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.continent.toLowerCase().contains(q) ||
            c.code.toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<AppCountry>> _group(List<AppCountry> countries) {
    final map = <String, List<AppCountry>>{};
    for (final c in countries) {
      map.putIfAbsent(c.continent, () => []).add(c);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }

  void _pick(AppCountry c) {
    _store.select(c);
    Navigator.of(context).pop(c);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final filtered = _filtered;
    final grouped = _group(filtered);
    final continents = grouped.keys.toList()
      ..sort((a, b) {
        // Custom continent order
        const order = ['Asia', 'Europe', 'North America', 'South America', 'Africa', 'Oceania'];
        final ai = order.indexOf(a);
        final bi = order.indexOf(b);
        if (ai == -1 && bi == -1) return a.compareTo(b);
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      });

    return Scaffold(
      backgroundColor: TravelColors.canvas,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            color: TravelColors.surface,
            padding: EdgeInsets.fromLTRB(8, top + 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: TravelColors.ink,
                    ),
                    Expanded(
                      child: Text(
                        'Choose Destination',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: TravelColors.ink,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: TravelColors.canvas,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search country…',
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: TravelColors.muted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: TravelColors.muted, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: TravelColors.muted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Detected location chip ─────────────────────────────────────
          if (widget.detectedCountry != null && _query.isEmpty)
            _DetectedBanner(
              country: widget.detectedCountry!,
              isSelected: _store.selected == widget.detectedCountry,
              onTap: () => _pick(widget.detectedCountry!),
            ),

          // ── Country list ───────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 48, color: TravelColors.muted),
                        const SizedBox(height: 12),
                        Text(
                          'No countries match "$_query"',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: TravelColors.muted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: continents.length,
                    itemBuilder: (context, ci) {
                      final continent = continents[ci];
                      final list = grouped[continent]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Text(
                              continent,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: TravelColors.navActive,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                          ),
                          for (final country in list)
                            _CountryTile(
                              country: country,
                              isSelected: _store.selected == country,
                              onTap: () => _pick(country),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _DetectedBanner extends StatelessWidget {
  const _DetectedBanner({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  final AppCountry country;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: TravelColors.navActive.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: TravelColors.navActive.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.my_location_rounded,
                  size: 18, color: TravelColors.navActive),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your location',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: TravelColors.navActive,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${country.emoji}  ${country.name}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: TravelColors.navActive, size: 20)
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TravelColors.navActive,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Select',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  final AppCountry country;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: isSelected
            ? TravelColors.navActive.withValues(alpha: 0.08)
            : TravelColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(
                  country.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country.name,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? TravelColors.navActive
                                      : TravelColors.ink,
                                ),
                      ),
                      Text(
                        country.capital,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TravelColors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_rounded,
                      color: TravelColors.navActive, size: 20)
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: TravelColors.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
