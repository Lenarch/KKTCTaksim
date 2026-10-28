import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sürücü bilgisini gösterir. Yolculuk başlarsa `true`, iptal edilirse `false` ile kapanır.
class DriverFoundSheet extends StatelessWidget {
  final Driver driver;

  const DriverFoundSheet({super.key, required this.driver});

  Future<void> _launch(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final launched = await launchUrl(uri);
    if (!launched) {
      messenger.showSnackBar(const SnackBar(content: Text('Bu işlem cihazınızda açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return SheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppTheme.ratingAmber, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(driver.rating.toStringAsFixed(1)),
                      ],
                    ),
                    Text('${driver.car} • ${driver.plate}', style: mutedStyle),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('Varış', style: mutedStyle),
                  Text(driver.eta, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launch(context, Uri(scheme: 'sms', path: driver.phone)),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Mesaj'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launch(context, Uri(scheme: 'tel', path: driver.phone)),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Ara'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YOLCULUĞU BAŞLAT (DEMO)'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Yolculuğu İptal Et'),
          ),
        ],
      ),
    );
  }
}
