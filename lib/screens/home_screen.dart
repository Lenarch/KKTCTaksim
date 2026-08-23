import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kktc_taksim/core/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.kktctaksim.taksi.app',
              ),
              MarkerLayer(
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

          // 2. Üst Arama Çubuğu
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Benzin istasyonları, ATM...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.mic),
                ),
              ),
            ),
          ),

          // 3. Alt Reklam Paneli (Manisa)
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
