import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/place.dart';
import 'package:kktc_taksim/services/location_service.dart';

class ExploreScreen extends StatefulWidget {
  /// "Buraya taksi çağır" ile seçilen yer ana sayfaya gönderilir.
  final ValueChanged<GeoPlace> onCallTaxi;

  const ExploreScreen({super.key, required this.onCallTaxi});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  /// null = tüm kategoriler.
  PlaceCategory? _selectedCategory;
  String _query = '';

  List<Place> _visiblePlaces(LatLng from) {
    final query = _query.trim().toLowerCase();
    return MockData.places.where((place) {
      final matchesCategory = _selectedCategory == null || place.category == _selectedCategory;
      final matchesQuery = query.isEmpty || place.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList()
      ..sort((a, b) => distanceMeters(from, a.position).compareTo(distanceMeters(from, b.position)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final categories = <PlaceCategory?>[null, ...PlaceCategory.values];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.explore)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.exploreSearchHint,
                prefixIcon: const Icon(Icons.search),
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category?.label(l10n) ?? l10n.categoryAll),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryBlack : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
            child: Text(
              l10n.popularPlaces,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<LatLng?>(
              valueListenable: LocationService.lastKnown,
              builder: (context, location, _) {
                final from = location ?? MockData.fallbackLocation;
                final places = _visiblePlaces(from);
                if (places.isEmpty) {
                  return Center(
                    child: Text(l10n.noPlacesFound, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return _PlaceCard(
                      place: place,
                      distanceMeters: distanceMeters(from, place.position),
                      onCallTaxi: () => widget.onCallTaxi(
                        GeoPlace(name: place.name, address: place.category.label(l10n), position: place.position),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final double distanceMeters;
  final VoidCallback onCallTaxi;

  const _PlaceCard({required this.place, required this.distanceMeters, required this.onCallTaxi});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final discount = place.discountPercent;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [place.imageColor, Color.lerp(place.imageColor, AppTheme.primaryBlack, 0.15)!],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(place.category.icon, size: 56, color: AppTheme.primaryBlack.withValues(alpha: 0.25)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (discount != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          l10n.discountBadge(discount),
                          style: const TextStyle(
                            color: AppTheme.primaryBlack,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(place.category.label(l10n), style: TextStyle(color: mutedColor, fontSize: 12)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.ratingAmber, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Icon(Icons.location_on, color: mutedColor, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(context.distance(distanceMeters), style: TextStyle(color: mutedColor, fontSize: 13)),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed: onCallTaxi,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: AppTheme.primaryBlack,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.local_taxi, size: 18),
                      label: Text(l10n.callTaxiHere),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
