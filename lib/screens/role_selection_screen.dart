import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/screens/login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo ve Başlık
              const Icon(
                Icons.local_taxi_rounded,
                size: 100,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 20),
              const Text(
                'KKTC TAKSİM',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Lütfen devam etmek için rolünüzü seçin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(),
              // Rol Butonları
              _buildRoleButton(
                context,
                title: 'Ben Yolcuyum',
                subtitle: 'Taksi çağırın, yolculuk paylaşın',
                icon: Icons.person_outline_rounded,
                color: AppTheme.primaryGreen,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
              const SizedBox(height: 20),
              _buildRoleButton(
                context,
                title: 'Ben Şoförüm',
                subtitle: 'Çağrıları yönetin, kazanç sağlayın',
                icon: Icons.drive_eta_rounded,
                color: AppTheme.secondaryBlack,
                onTap: () {
                  // İleride Şoför Giriş Ekranına gidecek
                },
              ),
              const SizedBox(height: 20),
              _buildRoleButton(
                context,
                title: 'Taksi Durağı',
                subtitle: 'Durağınızı ve filonuzu yönetin',
                icon: Icons.business_rounded,
                color: AppTheme.accentBlue,
                onTap: () {
                  // İleride Durak Giriş Ekranına gidecek
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.02),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
