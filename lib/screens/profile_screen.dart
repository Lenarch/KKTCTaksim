import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryYellow,
                    child: Icon(Icons.person, size: 70, color: AppTheme.primaryBlack),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tacettin',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '+90 533 123 45 67',
                    style: TextStyle(color: AppTheme.grayText),
                  ),
                ],
              ),
            ),

            // Menu Items
            _buildMenuItem(Icons.person_outline, 'Kişisel Bilgiler'),
            _buildMenuItem(Icons.bookmark_border, 'Kayıtlı Adresler'),
            _buildMenuItem(Icons.payment, 'Ödeme Yöntemleri'),
            _buildMenuItem(Icons.notifications_none, 'Bildirimler'),
            _buildMenuItem(Icons.campaign_outlined, 'Kampanyalar'),
            _buildMenuItem(Icons.help_outline, 'Yardım ve Destek'),
            _buildMenuItem(Icons.settings_outlined, 'Ayarlar'),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(),
            ),

            _buildMenuItem(Icons.logout, 'Çıkış Yap', isDestructive: true),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : AppTheme.primaryYellow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : AppTheme.primaryBlack, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : AppTheme.primaryBlack,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.grayText),
      onTap: () {},
    );
  }
}
