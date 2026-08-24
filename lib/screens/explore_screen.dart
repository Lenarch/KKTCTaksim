import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategory = 'Hepsi';

  final List<String> _categories = [
    'Hepsi',
    'Restoran',
    'Kafe',
    'Otel',
    'Eğlence',
    'Alışveriş',
    'Tarihi Yerler',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Yakınında ne arıyorsun?',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Categories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    selectedColor: AppTheme.primaryYellow,
                    backgroundColor: AppTheme.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryBlack : AppTheme.grayText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide.none,
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Popular Places
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Popüler Yerler',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildPlaceCard(
                  'Girne Yat Limanı',
                  'Tarihi Yerler',
                  '4.8',
                  '2.3 km',
                  '%10 İndirim',
                  Colors.blue[100]!,
                ),
                _buildPlaceCard(
                  'Bellapais Manastırı',
                  'Tarihi Yerler',
                  '4.9',
                  '5.1 km',
                  'Ücretsiz Giriş',
                  Colors.orange[100]!,
                ),
                _buildPlaceCard(
                  'Nezih Restoran',
                  'Restoran',
                  '4.5',
                  '0.8 km',
                  '%15 İndirim',
                  Colors.green[100]!,
                ),
                _buildPlaceCard(
                  'Elexus Resort',
                  'Otel',
                  '4.7',
                  '12.0 km',
                  'Özel Kampanya',
                  Colors.purple[100]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(String name, String category, String rating, String distance, String badge, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Icon(Icons.image, size: 50, color: Colors.black.withOpacity(0.1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primaryYellow, borderRadius: BorderRadius.circular(8)),
                      child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(category, style: const TextStyle(color: AppTheme.grayText, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 15),
                    const Icon(Icons.location_on, color: AppTheme.grayText, size: 16),
                    const SizedBox(width: 4),
                    Text(distance, style: const TextStyle(color: AppTheme.grayText, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
