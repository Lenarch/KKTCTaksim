import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/widgets/home/driver_card.dart';
import 'package:kktc_taksim/widgets/home/ride_sheet_closer.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

/// Devam eden yolculuk. Geri tuşuyla kapatılamaz; yolculuk tamamlanınca `true`,
/// iptal edilirse `false` ile kendiliğinden kapanır.
class ActiveTripSheet extends StatefulWidget {
  final RideRequest request;
  final Driver driver;
  final ValueListenable<RideSession?> session;
  final VoidCallback onSafety;

  /// Demo: şoför tarafı olmadığı için yolculuğu yolcu bitirir; null ise buton gösterilmez.
  final VoidCallback? onCompleteDemo;

  const ActiveTripSheet({
    super.key,
    required this.request,
    required this.driver,
    required this.session,
    required this.onSafety,
    this.onCompleteDemo,
  });

  @override
  State<ActiveTripSheet> createState() => _ActiveTripSheetState();
}

class _ActiveTripSheetState extends State<ActiveTripSheet> with RideSheetCloser {
  @override
  ValueListenable<RideSession?> get session => widget.session;

  @override
  Set<RideStatus> get closeOn => const {RideStatus.completed, RideStatus.cancelled};

  @override
  bool resultFor(RideStatus status) => status == RideStatus.completed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final request = widget.request;
    final onCompleteDemo = widget.onCompleteDemo;

    return PopScope(
      canPop: false,
      child: SheetContainer(
        child: SingleChildScrollView(
          child: ValueListenableBuilder<RideSession?>(
            valueListenable: widget.session,
            builder: (context, session, _) {
              final progress = session?.progress;
              final arrived = session?.status == RideStatus.arrived;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    arrived ? l10n.arrivedAtDestination : l10n.tripInProgress,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: mutedColor),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          request.destination.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: mutedColor),
                        ),
                      ),
                      if (!arrived) ...[
                        const SizedBox(width: AppSpacing.md),
                        Icon(Icons.access_time, size: 16, color: mutedColor),
                        const SizedBox(width: AppSpacing.xs),
                        Text(l10n.minutesLeft(progress?.minutesLeft ?? 0), style: TextStyle(color: mutedColor)),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    value: arrived ? 1 : progress?.fraction ?? 0,
                    color: arrived ? AppTheme.successGreen : AppTheme.primaryYellow,
                    backgroundColor: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DriverCard(driver: widget.driver),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(request.payment.icon, size: 18, color: mutedColor),
                      const SizedBox(width: AppSpacing.sm),
                      Text(request.payment.label(l10n), style: TextStyle(color: mutedColor)),
                      const Spacer(),
                      Text(
                        '${l10n.estimated} ${context.fareRange(request.fare)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onSafety,
                          icon: const Icon(Icons.security),
                          label: Text(l10n.safetyTools),
                        ),
                      ),
                      if (onCompleteDemo != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onCompleteDemo,
                            style: arrived
                                ? null
                                : ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                  ),
                            child: Text(arrived ? l10n.completeRide : l10n.finishDemo),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
