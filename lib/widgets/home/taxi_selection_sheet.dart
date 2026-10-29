import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/fare_calculator.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/route_info.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

/// Taksi tipi, ödeme yöntemi ve zamanı seçtirir; onaylanan [RideRequest] ile kapanır.
class TaxiSelectionSheet extends StatefulWidget {
  final GeoPlace pickup;
  final GeoPlace destination;
  final RouteInfo route;

  const TaxiSelectionSheet({super.key, required this.pickup, required this.destination, required this.route});

  /// Rezervasyon en erken bu kadar sonrasına, en geç bu kadar ileriye yapılabilir.
  static const Duration minimumLeadTime = Duration(minutes: 30);
  static const Duration maximumLeadTime = Duration(days: 30);

  @override
  State<TaxiSelectionSheet> createState() => _TaxiSelectionSheetState();
}

class _TaxiSelectionSheetState extends State<TaxiSelectionSheet> {
  TaxiType _type = TaxiType.economy;
  PaymentMethod _payment = PaymentMethod.cash;
  DateTime? _scheduledAt;

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final earliest = now.add(TaxiSelectionSheet.minimumLeadTime);
    final initial = _scheduledAt ?? DateTime(now.year, now.month, now.day, now.hour + 1);

    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(earliest) ? earliest : initial,
      firstDate: DateUtils.dateOnly(earliest),
      lastDate: now.add(TaxiSelectionSheet.maximumLeadTime),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;

    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (selected.isBefore(earliest)) {
      showMessage(context, context.l10n.scheduleTooSoon(TaxiSelectionSheet.minimumLeadTime.inMinutes));
      return;
    }
    setState(() => _scheduledAt = selected);
  }

  void _confirm() {
    Navigator.pop(
      context,
      RideRequest(
        pickup: widget.pickup,
        destination: widget.destination,
        route: widget.route,
        taxiType: _type,
        payment: _payment,
        fare: FareCalculator.estimate(widget.route.distanceKm, _type),
        scheduledAt: _scheduledAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final route = widget.route;
    final scheduledAt = _scheduledAt;

    final tripSummary = '${context.distance(route.distanceMeters)} • ${context.minutes(route.durationMinutes)}';

    return SheetContainer(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.destination.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              route.isApproximate ? l10n.approximateRoute(tripSummary) : tripSummary,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final type in TaxiType.values)
              _TaxiTypeTile(
                type: type,
                fare: context.fareRange(FareCalculator.estimate(route.distanceKm, type)),
                selected: type == _type,
                onTap: () => setState(() => _type = type),
              ),
            Text(
              l10n.fareDisclaimer,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Label(l10n.paymentMethod),
            SegmentedButton<PaymentMethod>(
              showSelectedIcon: false,
              segments: [
                for (final method in PaymentMethod.values)
                  ButtonSegment(value: method, icon: Icon(method.icon), label: Text(method.label(l10n))),
              ],
              selected: {_payment},
              onSelectionChanged: (selection) => setState(() => _payment = selection.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Label(l10n.when),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, icon: const Icon(Icons.bolt), label: Text(l10n.now)),
                ButtonSegment(value: true, icon: const Icon(Icons.event), label: Text(l10n.later)),
              ],
              selected: {scheduledAt != null},
              onSelectionChanged: (selection) {
                if (selection.first) {
                  _pickSchedule();
                } else {
                  setState(() => _scheduledAt = null);
                }
              },
            ),
            if (scheduledAt != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(context.dateTime(scheduledAt), style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: TextButton(onPressed: _pickSchedule, child: Text(l10n.change)),
              ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _confirm,
              child: Text(scheduledAt == null ? l10n.callTaxi : l10n.reserveTaxi),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _TaxiTypeTile extends StatelessWidget {
  final TaxiType type;
  final String fare;
  final bool selected;
  final VoidCallback onTap;

  const _TaxiTypeTile({required this.type, required this.fare, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(AppRadius.lg);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? AppTheme.primaryYellow.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: selected ? AppTheme.primaryYellow : theme.colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  type.icon,
                  size: 40,
                  color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.label(l10n), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        l10n.pickupIn(type.pickupMinutes),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.estimated,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(fare, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
