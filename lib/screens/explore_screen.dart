import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/models/place.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategory = MockData.allCategories;
  String _query = '';

  List<Place> get _visiblePlaces {
    final query = _query.trim().toLowerCase();
    return MockData.places.where((place) {
      final matchesCategory =
          _selectedCategory == MockData.allCategories || place.category == _selectedCategory;
      final matchesQuery = query.isEmpty || place.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final places = _visiblePlaces;

    return Scaffold(
      appBar: AppBar(title: const Text('Keşfet')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Yakınında ne arıyorsun?',
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
              itemCount: MockData.placeCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = MockData.placeCategories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
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
              'Popüler Yerler',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: places.isEmpty
                ? Center(
                    child: Text(
                      'Aramana uygun yer bulunamadı',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    itemCount: places.length,
                    itemBuilder: (context, index) => _PlaceCard(place: places[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;

  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            color: place.imageColor,
            alignment: Alignment.center,
            child: Icon(Icons.image, size: 50, color: Colors.black.withValues(alpha: 0.1)),
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
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        place.badge,
                        style: const TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(place.category, style: TextStyle(color: mutedColor, fontSize: 12)),
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
                    Text(
                      '${place.distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(color: mutedColor, fontSize: 13),
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
