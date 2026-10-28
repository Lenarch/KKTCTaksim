import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/models/taxi_option.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

/// Taksi tipini seçtirir; seçilen [TaxiOption] ile kapanır.
class TaxiSelectionSheet extends StatefulWidget {
  final String destination;

  const TaxiSelectionSheet({super.key, required this.destination});

  @override
  State<TaxiSelectionSheet> createState() => _TaxiSelectionSheetState();
}

class _TaxiSelectionSheetState extends State<TaxiSelectionSheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Senin için taksiler',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.destination,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < MockData.taxiOptions.length; i++)
            _TaxiOptionTile(
              option: MockData.taxiOptions[i],
              selected: i == _selectedIndex,
              onTap: () => setState(() => _selectedIndex = i),
            ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, MockData.taxiOptions[_selectedIndex]),
            child: const Text('TAKSİ ÇAĞIR'),
          ),
        ],
      ),
    );
  }
}

class _TaxiOptionTile extends StatelessWidget {
  final TaxiOption option;
  final bool selected;
  final VoidCallback onTap;

  const _TaxiOptionTile({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  option.icon,
                  size: 40,
                  color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        option.eta,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatLira(option.price),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
