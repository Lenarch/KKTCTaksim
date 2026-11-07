import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';

/// Haritanın üstünde yönerge şeridi (haritadan seçerken).
class MapTopBanner extends StatelessWidget {
  final String text;

  const MapTopBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.pan_tool_alt_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Haritanın tam ortasını gösteren iğne; ucu merkezde olsun diye yukarı kaydırılır.
class MapCenterPin extends StatelessWidget {
  static const double _size = 48;

  const MapCenterPin({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: _size),
          child: Icon(Icons.location_on, size: _size, color: AppTheme.errorRed),
        ),
      ),
    );
  }
}
