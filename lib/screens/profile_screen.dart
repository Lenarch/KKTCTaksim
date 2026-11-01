import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/core/legal_links.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/models/app_user.dart';
import 'package:kktc_taksim/screens/otp_screen.dart';
import 'package:kktc_taksim/services/app_settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await confirm(
      context,
      title: l10n.logout,
      message: l10n.logoutMessage,
      confirmLabel: l10n.logout,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await Backend.instance.auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
    }
  }

  Future<void> _openLegal(BuildContext context, Uri url) async {
    final message = context.l10n.cannotOpen;
    final opened = await openLegalPage(url);
    if (!opened && context.mounted) showMessage(context, message);
  }

  /// Onay → SMS koduyla yeniden doğrulama → veriler ve hesap silinir (OtpScreen).
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = context.l10n;
    final user = Backend.instance.auth.currentUser;
    if (user == null) return;
    final confirmed = await confirm(
      context,
      title: l10n.deleteAccount,
      message: l10n.deleteAccountMessage,
      confirmLabel: l10n.deleteAccount,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await Backend.instance.auth.sendCode(user.phone);
    } on AuthException catch (e) {
      if (context.mounted) showMessage(context, e.code.label(l10n));
      return;
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OtpScreen(phoneNumber: user.phone, purpose: OtpPurpose.deleteAccount),
      ),
    );
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final l10n = context.l10n;
    final settings = AppSettings.instance;
    // Dil adları her dilde kendi yazımıyla gösterilir.
    final options = <(Locale?, String)>[
      (null, l10n.languageSystem),
      (const Locale('tr'), 'Türkçe'),
      (const Locale('en'), 'English'),
    ];

    final selected = await showDialog<(Locale?, String)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          for (final option in options)
            ListTile(
              leading: Icon(
                option.$1 == settings.locale.value ? Icons.radio_button_checked : Icons.radio_button_off,
              ),
              title: Text(option.$2),
              onTap: () => Navigator.pop(context, option),
            ),
        ],
      ),
    );
    if (selected != null) await settings.setLocale(selected.$1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final comingSoonItems = [
      (Icons.person_outline, l10n.personalInfo),
      (Icons.bookmark_border, l10n.savedAddresses),
      (Icons.payment, l10n.paymentMethods),
      (Icons.notifications_none, l10n.notifications),
      (Icons.campaign_outlined, l10n.campaigns),
      (Icons.help_outline, l10n.helpSupport),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryYellow,
                  child: Icon(Icons.person, size: 70, color: AppTheme.primaryBlack),
                ),
                SizedBox(height: AppSpacing.xl),
                _UserHeader(),
              ],
            ),
          ),
          for (final (icon, title) in comingSoonItems)
            _MenuItem(icon: icon, title: title, onTap: () => showComingSoon(context, title)),
          ValueListenableBuilder<Locale?>(
            valueListenable: AppSettings.instance.locale,
            builder: (context, locale, _) => _MenuItem(
              icon: Icons.language,
              title: l10n.language,
              trailing: switch (locale?.languageCode) {
                'tr' => 'Türkçe',
                'en' => 'English',
                _ => l10n.languageSystem,
              },
              onTap: () => _chooseLanguage(context),
            ),
          ),
          _MenuItem(
            icon: Icons.drive_eta_outlined,
            title: l10n.switchToDriver,
            onTap: () async {
              await AppSettings.instance.setRole(AppRole.driver);
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.driver, (route) => false);
              }
            },
          ),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () => _openLegal(context, privacyPolicyUrl),
          ),
          _MenuItem(
            icon: Icons.description_outlined,
            title: l10n.termsOfUseTitle,
            onTap: () => _openLegal(context, termsOfUseUrl),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            child: Divider(),
          ),
          _MenuItem(
            icon: Icons.logout,
            title: l10n.logout,
            isDestructive: true,
            onTap: () => _confirmLogout(context),
          ),
          _MenuItem(
            icon: Icons.delete_forever_outlined,
            title: l10n.deleteAccount,
            isDestructive: true,
            onTap: () => _confirmDeleteAccount(context),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  /// Sağda, oktan önce gösterilen o anki değer (örn. seçili dil).
  final String? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;
    final trailing = this.trailing;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: (isDestructive ? colorScheme.error : AppTheme.primaryYellow).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            Text(trailing, style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(width: AppSpacing.sm),
          ],
          Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Ad ve telefon. Akış State'te tutulur: liste kaydırılıp başlık yeniden oluşturulunca aynı
/// (tek dinleyicili) akışa ikinci kez abone olunup "Stream has already been listened to" oluyordu.
class _UserHeader extends StatefulWidget {
  const _UserHeader();

  @override
  State<_UserHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends State<_UserHeader> {
  late final Stream<AppUser?> _user = Backend.instance.auth.authState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<AppUser?>(
      stream: _user,
      initialData: Backend.instance.auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?.name;
        return Column(
          children: [
            if (name != null && name.isNotEmpty)
              Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (user != null) Text(user.phone, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        );
      },
    );
  }
}
