import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/models/trip.dart';

class MyTripsScreen extends StatelessWidget {
  /// "Taksi Çağır" butonuna basılınca ana sayfa sekmesine geçmek için.
  final VoidCallback onCallTaxi;

  const MyTripsScreen({super.key, required this.onCallTaxi});

  List<Trip> _tripsWith(TripStatus status) =>
      MockData.trips.where((trip) => trip.status == status).toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yolculuklarım'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Yaklaşan'),
              Tab(text: 'Geçmiş'),
              Tab(text: 'İptal Edilen'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TripList(
              trips: _tripsWith(TripStatus.upcoming),
              empty: _EmptyTrips(onCallTaxi: onCallTaxi),
            ),
            _TripList(
              trips: _tripsWith(TripStatus.completed),
              empty: const Center(child: Text('Henüz tamamlanmış yolculuğun yok')),
            ),
            _TripList(
              trips: _tripsWith(TripStatus.cancelled),
              empty: const Center(child: Text('İptal edilmiş yolculuğun yok')),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  final List<Trip> trips;
  final Widget empty;

  const _TripList({required this.trips, required this.empty});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) return empty;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: trips.length,
      itemBuilder: (context, index) => _TripCard(trip: trips[index]),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  final VoidCallback onCallTaxi;

  const _EmptyTrips({required this.onCallTaxi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Yaklaşan yolculuğun yok',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Yeni bir yolculuk planlamak ister misin?',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            ElevatedButton(
              onPressed: onCallTaxi,
              child: const Text('Taksi Çağır'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  (String, Color) get _statusLabel => switch (trip.status) {
        TripStatus.upcoming => ('Planlandı', AppTheme.locationBlue),
        TripStatus.completed => ('Tamamlandı', AppTheme.successGreen),
        TripStatus.cancelled => ('İptal Edildi', AppTheme.errorRed),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (status, statusColor) = _statusLabel;
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, size: 12, color: AppTheme.primaryYellow),
                    Container(width: 2, height: 20, color: theme.colorScheme.outlineVariant),
                    const Icon(Icons.location_on, size: 16, color: AppTheme.errorRed),
                  ],
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.from, style: boldStyle),
                      const SizedBox(height: AppSpacing.lg),
                      Text(trip.to, style: boldStyle),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatLira(trip.price),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip.date,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                TextButton(
                  onPressed: () => showComingSoon(context, 'Yolculuk detayı'),
                  child: const Text('Detayları Gör'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
