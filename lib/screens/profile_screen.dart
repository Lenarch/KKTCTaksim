import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/mock_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const menuItems = [
      (Icons.person_outline, 'Kişisel Bilgiler'),
      (Icons.bookmark_border, 'Kayıtlı Adresler'),
      (Icons.payment, 'Ödeme Yöntemleri'),
      (Icons.notifications_none, 'Bildirimler'),
      (Icons.campaign_outlined, 'Kampanyalar'),
      (Icons.help_outline, 'Yardım ve Destek'),
      (Icons.settings_outlined, 'Ayarlar'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryYellow,
                  child: Icon(Icons.person, size: 70, color: AppTheme.primaryBlack),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  MockData.userName,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(MockData.userPhone, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          for (final (icon, title) in menuItems)
            _MenuItem(icon: icon, title: title, onTap: () => showComingSoon(context, title)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            child: Divider(),
          ),
          _MenuItem(
            icon: Icons.logout,
            title: 'Çıkış Yap',
            isDestructive: true,
            onTap: () => _confirmLogout(context),
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

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;

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
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
