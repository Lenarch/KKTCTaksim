import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/models/payment_method.dart';

/// Yolculuk özeti ve puanlama. Verilen puanla (1-5) kapanır.
class TripCompletedDialog extends StatefulWidget {
  final int price;
  final PaymentMethod payment;

  const TripCompletedDialog({super.key, required this.price, required this.payment});

  @override
  State<TripCompletedDialog> createState() => _TripCompletedDialogState();
}

class _TripCompletedDialogState extends State<TripCompletedDialog> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 80),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.tripCompleted,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.totalAmount(context.lira(widget.price)),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.payment.icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(widget.payment.label(l10n), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(l10n.howWasTrip, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  tooltip: l10n.starCount(star),
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: AppTheme.ratingAmber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _rating),
              child: Text(l10n.submitRating),
            ),
          ],
        ),
      ),
    );
  }
}
