import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/widgets/async_view.dart';
import 'package:kktc_taksim/models/trip.dart';

class MyTripsScreen extends StatelessWidget {
  /// "Taksi Çağır" butonuna basılınca ana sayfa sekmesine geçmek için.
  final VoidCallback onCallTaxi;

  const MyTripsScreen({super.key, required this.onCallTaxi});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myTrips),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabUpcoming),
              Tab(text: l10n.tabPast),
              Tab(text: l10n.tabCancelled),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TripList(
              status: TripStatus.upcoming,
              empty: _EmptyTrips(onCallTaxi: onCallTaxi),
            ),
            _TripList(
              status: TripStatus.completed,
              empty: Center(child: Text(l10n.noPastTrips)),
            ),
            _TripList(
              status: TripStatus.cancelled,
              empty: Center(child: Text(l10n.noCancelledTrips)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripList extends StatefulWidget {
  final TripStatus status;
  final Widget empty;

  const _TripList({required this.status, required this.empty});

  @override
  State<_TripList> createState() => _TripListState();
}

class _TripListState extends State<_TripList> {
  // Akış bir kez oluşturulur; her build'de yeniden abone olunmasın.
  late Stream<List<Trip>> _trips = Backend.instance.trips.watch(widget.status);

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Trip>>(
      stream: _trips,
      onRetry: () => setState(() => _trips = Backend.instance.trips.watch(widget.status)),
      builder: (context, trips) {
        if (trips.isEmpty) return widget.empty;
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.xl),
          itemCount: trips.length,
          itemBuilder: (context, index) => _TripCard(trip: trips[index]),
        );
      },
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  final VoidCallback onCallTaxi;

  const _EmptyTrips({required this.onCallTaxi});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              l10n.noUpcomingTrips,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.noUpcomingTripsHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            ElevatedButton(
              onPressed: onCallTaxi,
              child: Text(l10n.callTaxiShort),
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

  (String, Color) _statusLabel(AppLocalizations l10n) => switch (trip.status) {
        TripStatus.upcoming => (l10n.statusScheduled, AppTheme.locationBlue),
        TripStatus.completed => (l10n.statusCompleted, AppTheme.successGreen),
        TripStatus.cancelled => (l10n.statusCancelled, AppTheme.errorRed),
      };

  Future<void> _cancel(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await confirm(
      context,
      title: l10n.cancelReservationTitle,
      message: l10n.cancelReservationMessage(context.dateTime(trip.dateTime)),
      confirmLabel: l10n.cancelReservation,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await Backend.instance.trips.cancel(trip.id);
    } catch (_) {
      if (context.mounted) showMessage(context, l10n.actionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final (status, statusColor) = _statusLabel(l10n);
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);
    final isUpcoming = trip.status == TripStatus.upcoming;

    final details = [
      if (trip.taxiType != null) trip.taxiType!.label(l10n),
      if (trip.payment != null) trip.payment!.label(l10n),
    ].join(' • ');

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
                      Text(trip.from, style: boldStyle, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.lg),
                      Text(trip.to, style: boldStyle, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isUpcoming) Text(l10n.estimated, style: mutedStyle),
                    Text(
                      context.lira(trip.price),
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.dateTime(trip.dateTime), style: mutedStyle),
                      if (details.isNotEmpty) Text(details, style: mutedStyle),
                    ],
                  ),
                ),
                if (isUpcoming)
                  TextButton(
                    onPressed: () => _cancel(context),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    child: Text(l10n.cancelReservation),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
