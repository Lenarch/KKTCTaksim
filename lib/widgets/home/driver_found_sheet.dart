import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/widgets/home/driver_card.dart';
import 'package:kktc_taksim/widgets/home/ride_sheet_closer.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sürücü yolcuya gelirken gösterilir. Yolculuk başlayınca `true`, iptal edilince `false` ile kapanır.
class DriverFoundSheet extends StatefulWidget {
  final Driver driver;
  final ValueListenable<RideSession?> session;

  /// Demo: şoför tarafı olmadığı için yolculuğu yolcu başlatır; null ise buton gösterilmez.
  final VoidCallback? onStartDemo;

  const DriverFoundSheet({super.key, required this.driver, required this.session, this.onStartDemo});

  @override
  State<DriverFoundSheet> createState() => _DriverFoundSheetState();
}

class _DriverFoundSheetState extends State<DriverFoundSheet> with RideSheetCloser {
  @override
  ValueListenable<RideSession?> get session => widget.session;

  @override
  Set<RideStatus> get closeOn => const {RideStatus.inProgress, RideStatus.cancelled};

  @override
  bool resultFor(RideStatus status) => status == RideStatus.inProgress;

  Future<void> _launch(Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.cannotOpen;
    final launched = await launchUrl(uri);
    if (!launched) messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final confirmed = await confirm(
      context,
      title: l10n.cancelRideTitle,
      message: l10n.cancelRideMessage,
      confirmLabel: l10n.cancelRide,
      destructive: true,
    );
    if (confirmed && mounted) close(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final driver = widget.driver;
    final onStartDemo = widget.onStartDemo;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: SheetContainer(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueListenableBuilder<RideSession?>(
                valueListenable: widget.session,
                builder: (context, session, _) {
                  final progress = session?.progress;
                  final arrived = session?.status == RideStatus.driverArrived;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        arrived ? l10n.driverArrived : l10n.driverOnTheWay(progress?.minutesLeft ?? 0),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LinearProgressIndicator(
                        value: arrived ? 1 : progress?.fraction ?? 0,
                        color: arrived ? AppTheme.successGreen : AppTheme.primaryYellow,
                        backgroundColor: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              DriverCard(driver: driver),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launch(Uri(scheme: 'sms', path: driver.phone)),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(l10n.message),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launch(Uri(scheme: 'tel', path: driver.phone)),
                      icon: const Icon(Icons.call_outlined),
                      label: Text(l10n.call),
                    ),
                  ),
                ],
              ),
              if (onStartDemo != null) ...[
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(onPressed: onStartDemo, child: Text(l10n.startRideDemo)),
              ],
              TextButton(
                onPressed: _cancel,
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                child: Text(l10n.cancelRide),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
