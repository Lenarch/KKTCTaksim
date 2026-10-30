import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

/// KKTC acil durum numaraları.
class EmergencyNumbers {
  EmergencyNumbers._();

  static const String police = '155';
  static const String ambulance = '112';
  static const String fire = '199';
}

/// Yolculuk sırasında: yolculuğu bir yakınla paylaşma ve acil arama.
class SafetySheet extends StatelessWidget {
  /// Paylaşılacak metni hazırlar (sürücü, plaka, rota ve canlı takip bağlantısı). Canlı
  /// paylaşımı başlatmak sunucuya gittiği için asenkron.
  final Future<String> Function() shareText;

  const SafetySheet({super.key, required this.shareText});

  Future<void> _share(BuildContext context) async {
    final copiedMessage = context.l10n.tripDetailsCopied;
    final text = await shareText();
    try {
      final result = await SharePlus.instance.share(ShareParams(text: text));
      if (result.status != ShareResultStatus.unavailable) return;
    } catch (_) {
      // Paylaşım menüsü olmayan tarayıcılarda panoya kopyalanır.
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) showMessage(context, copiedMessage);
  }

  Future<void> _call(BuildContext context, String number) async {
    final message = context.l10n.cannotOpen;
    final launched = await launchUrl(Uri(scheme: 'tel', path: number));
    if (!launched && context.mounted) showMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    return SheetContainer(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.safetyTools,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryYellow,
                child: Icon(Icons.share_location, color: AppTheme.primaryBlack),
              ),
              title: Text(l10n.shareTrip, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.shareTripHint),
              onTap: () => _share(context),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(l10n.emergencyCall, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            for (final (icon, label, number) in [
              (Icons.local_police_outlined, l10n.police, EmergencyNumbers.police),
              (Icons.medical_services_outlined, l10n.ambulance, EmergencyNumbers.ambulance),
              (Icons.local_fire_department_outlined, l10n.fireDepartment, EmergencyNumbers.fire),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: error.withValues(alpha: 0.12),
                  child: Icon(icon, color: error),
                ),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text(number, style: theme.textTheme.titleMedium?.copyWith(color: error, fontWeight: FontWeight.bold)),
                onTap: () => _call(context, number),
              ),
          ],
        ),
      ),
    );
  }
}
