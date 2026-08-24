import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              _buildMenuOption(
                context,
                title: 'Ayarlar',
                icon: Icons.settings_outlined,
                onTap: () {
                  Navigator.pop(context);
                  // Ayarlar sayfasına yönlendirme eklenebilir
                },
              ),
              const SizedBox(height: 10),
              _buildMenuOption(
                context,
                title: 'Hesap',
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.pop(context);
                  // Hesap sayfasına yönlendirme eklenebilir
                },
              ),
              const Divider(height: 30),
              _buildMenuOption(
                context,
                title: 'Çıkış Yap',
                icon: Icons.logout_rounded,
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context); // Menüyü kapat
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false, // Tüm geçmişi temizle
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppTheme.secondaryBlack,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  void _showTaxiOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Nasıl bir taksi istersiniz?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryBlack,
                ),
              ),
              const SizedBox(height: 25),
              _buildTaxiOption(
                context,
                title: 'Hızlı Taksi Çağır',
                subtitle: 'En yakın taksi anında size yönlendirilir.',
                icon: Icons.bolt_rounded,
                color: AppTheme.primaryGreen,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hızlı taksi aranıyor...')),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildTaxiOption(
                context,
                title: 'Kendim Seçerim',
                subtitle: 'Haritadaki taksilerden dilediğinizi seçin.',
                icon: Icons.ads_click_rounded,
                color: AppTheme.secondaryBlack,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Taksi seçim ekranına yönlendiriliyorsunuz...')),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxiOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Harita Katmanı
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(38.6140, 27.4296), // Manisa Koordinatları
              initialZoom: 14.0,
              interactionOptions: InteractionOptions(
                // Haritayı iki parmakla döndürmeyi (rotate) tamamen kapattık
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.kktctaksim.taksi.app',
              ),
              MarkerLayer(
                rotate: false,
                markers: [
                  Marker(
                    point: const LatLng(38.6140, 27.4296),
                    width: 80,
                    height: 80,
                    child: Icon(
                      Icons.location_on,
                      color: AppTheme.primaryGreen,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Üst Arama Çubuğu ve Ayarlar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Nereye gitmek istersiniz?',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: AppTheme.primaryGreen),
                        suffixIcon: Icon(Icons.mic, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showSettingsMenu(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: AppTheme.secondaryBlack,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Taksi Çağır Butonu (Dikkat Çekici)
          Positioned(
            bottom: 130, // Panel kapalıyken hemen üstünde durması için
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showTaxiOptions(context),
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0, // Kendi shadow'umuzu verdik
                label: const Text(
                  'TAKSİ ÇAĞIR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 16,
                  ),
                ),
                icon: const Icon(Icons.local_taxi_rounded, size: 28),
              ),
            ),
          ),

          // 4. Alt Reklam Paneli (Manisa)
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.1,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Manisa',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
                              SizedBox(width: 4),
                              Text('30°', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text('Anlaşmalı Mekanlar & Mağazalar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    _buildAdItem(
                      'Hilal Pasta & Kebap',
                      'Harika lezzetler, %10 indirim!',
                      Icons.restaurant,
                    ),
                    _buildAdItem(
                      'Manisloft Sitesi',
                      'Konforlu yaşam alanları',
                      Icons.business,
                    ),
                    _buildAdItem(
                      'Asya Ergül Beauty',
                      'Güzellik ve bakımda öncü',
                      Icons.face,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
        child: Icon(icon, color: AppTheme.primaryGreen),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}
