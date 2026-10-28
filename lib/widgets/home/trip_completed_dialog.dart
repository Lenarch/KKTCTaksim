import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';

/// Yolculuk özeti ve puanlama. Verilen puanla (1-5) kapanır.
class TripCompletedDialog extends StatefulWidget {
  final int price;

  const TripCompletedDialog({super.key, required this.price});

  @override
  State<TripCompletedDialog> createState() => _TripCompletedDialogState();
}

class _TripCompletedDialogState extends State<TripCompletedDialog> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 80),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Yolculuk Tamamlandı',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Toplam Tutar: ${formatLira(widget.price)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('Yolculuğun nasıl geçti?', style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  tooltip: '$star yıldız',
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
              child: const Text('Değerlendirmeyi Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}
