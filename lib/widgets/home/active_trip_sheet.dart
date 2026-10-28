import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/models/taxi_option.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

/// Devam eden yolculuk. Geri tuşuyla kapatılamaz; yolculuk bitince `true` ile kapanır.
class ActiveTripSheet extends StatelessWidget {
  final String destination;
  final TaxiOption option;

  const ActiveTripSheet({super.key, required this.destination, required this.option});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return PopScope(
      canPop: false,
      child: SheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Yolculuğun devam ediyor',
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
                    '$destination • ${option.name}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mutedColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16, color: mutedColor),
                const SizedBox(width: AppSpacing.xs),
                Text('12 dk kaldı', style: TextStyle(color: mutedColor)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryYellow,
                  child: Icon(Icons.security, color: AppTheme.primaryBlack),
                ),
                const SizedBox(width: AppSpacing.lg),
                const Expanded(
                  child: Text('Güvenlik Araçları', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    minimumSize: const Size(100, 40),
                  ),
                  child: const Text('BİTİR (DEMO)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
