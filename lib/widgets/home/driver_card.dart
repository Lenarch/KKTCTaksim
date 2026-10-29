import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/models/driver.dart';

/// Sürücünün yüzü, adı, puanı, aracı ve plakası. Yolcunun doğru araca binmesi
/// için plaka ve araç rengi öne çıkarılır.
class DriverCard extends StatelessWidget {
  final Driver driver;

  const DriverCard({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.primaryYellow,
          child: Text(
            driver.initials,
            style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold),
          ),
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
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: driver.carColor.swatch,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      '${driver.car} • ${driver.carColor.label(l10n)}',
                      style: mutedStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        LicensePlate(plate: driver.plate),
      ],
    );
  }
}

/// KKTC plakasına benzeyen beyaz zeminli, siyah çerçeveli plaka.
class LicensePlate extends StatelessWidget {
  final String plate;

  const LicensePlate({super.key, required this.plate});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.plateLabel(plate),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppTheme.primaryBlack, width: 2),
        ),
        child: Text(
          plate,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
        ),
      ),
    );
  }
}
