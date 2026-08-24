import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yolculuklarım'),
          bottom: TabBar(
            indicatorColor: AppTheme.primaryYellow,
            labelColor: AppTheme.primaryBlack,
            unselectedLabelColor: AppTheme.grayText,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Yaklaşan'),
              Tab(text: 'Geçmiş'),
              Tab(text: 'İptal Edilen'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUpcomingTrips(),
            _buildPastTrips(),
            _buildCancelledTrips(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTrips() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'Yaklaşan yolculuğun yok',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('Yeni bir yolculuk planlamak ister misin?'),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Taksi Çağır'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastTrips() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTripCard(
          'Lefkoşa Merkez',
          'Ercan Havalimanı',
          '24 Ağustos 2026',
          '₺420,00',
          'Tamamlandı',
          AppTheme.successGreen,
        ),
        _buildTripCard(
          'Girne Yat Limanı',
          'Lefkoşa Surlariçi',
          '20 Ağustos 2026',
          '₺350,00',
          'Tamamlandı',
          AppTheme.successGreen,
        ),
      ],
    );
  }

  Widget _buildCancelledTrips() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTripCard(
          'Gönyeli',
          'Gazimağusa',
          '15 Ağustos 2026',
          '₺0,00',
          'İptal Edildi',
          AppTheme.errorRed,
        ),
      ],
    );
  }

  Widget _buildTripCard(String from, String to, String date, String price, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, size: 12, color: AppTheme.primaryYellow),
                    Container(width: 2, height: 20, color: Colors.grey[300]),
                    const Icon(Icons.location_on, size: 16, color: AppTheme.errorRed),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(from, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Text(to, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(color: AppTheme.grayText, fontSize: 12)),
                TextButton(
                  onPressed: () {},
                  child: const Text('Detayları Gör'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
