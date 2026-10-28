import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.huge),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                      ),
                      child: const Icon(Icons.local_taxi_rounded, size: 72, color: AppTheme.primaryBlack),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'KKTC TAKSİM',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Lütfen devam etmek için rolünüzü seçin',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.xxxl),
                    _RoleButton(
                      title: 'Ben Yolcuyum',
                      subtitle: 'Taksi çağırın, yolculuk paylaşın',
                      icon: Icons.person_outline_rounded,
                      highlighted: true,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RoleButton(
                      title: 'Ben Şoförüm',
                      subtitle: 'Çağrıları yönetin, kazanç sağlayın',
                      icon: Icons.drive_eta_rounded,
                      onTap: () => showComingSoon(context, 'Şoför girişi'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RoleButton(
                      title: 'Taksi Durağı',
                      subtitle: 'Durağınızı ve filonuzu yönetin',
                      icon: Icons.business_rounded,
                      onTap: () => showComingSoon(context, 'Durak girişi'),
                    ),
                    const SizedBox(height: AppSpacing.huge),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(AppRadius.xl);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: highlighted ? AppTheme.primaryYellow : theme.colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: highlighted ? AppTheme.primaryYellow : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: highlighted ? AppTheme.primaryBlack : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
