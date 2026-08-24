import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SharedRideScreen extends StatefulWidget {
  const SharedRideScreen({super.key});

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  final List<Map<String, dynamic>> _rides = [
    {
      'from': 'Lefkoşa',
      'to': 'Ercan Havalimanı',
      'date': '24.08.2026',
      'time': '14:30',
      'capacity': 8,
      'current': 3,
      'price': 90,
    },
    {
      'from': 'Girne',
      'to': 'Lefkoşa',
      'date': '25.08.2026',
      'time': '10:00',
      'capacity': 8,
      'current': 5,
      'price': 75,
    },
  ];

  void _showCreateRideBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateSharedRideBottomSheet(),
    ).then((value) {
      if (value != null && value is Map<String, dynamic>) {
        setState(() {
          _rides.add(value);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Paylaşımlı Yolculuk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birlikte yolculuk et,\ndaha avantajlı öde.',
                          style: GoogleFonts.poppins(
                            color: AppTheme.primaryYellow,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aynı yöne giden kişilerle maliyeti paylaş.',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.group_add, color: AppTheme.primaryYellow, size: 50),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Aktif Gruplar',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _rides.length,
              itemBuilder: (context, index) {
                final ride = _rides[index];
                return _buildRideCard(ride);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRideBottomSheet,
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: AppTheme.primaryBlack,
        icon: const Icon(Icons.add),
        label: const Text('Grup Oluştur'),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    double progress = ride['current'] / ride['capacity'];
    bool isFull = ride['current'] >= ride['capacity'];

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, color: AppTheme.primaryYellow, size: 12),
                        const SizedBox(width: 10),
                        Text(ride['from'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.errorRed, size: 12),
                        const SizedBox(width: 10),
                        Text(ride['to'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                Text(
                  '₺${ride['price']}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(),
            ),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.grayText),
                const SizedBox(width: 8),
                Text(ride['date'], style: const TextStyle(color: AppTheme.grayText, fontSize: 13)),
                const SizedBox(width: 20),
                const Icon(Icons.access_time, size: 16, color: AppTheme.grayText),
                const SizedBox(width: 8),
                Text(ride['time'], style: const TextStyle(color: AppTheme.grayText, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${ride['current']} / ${ride['capacity']} kişi',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            isFull ? 'Dolu' : '${ride['capacity'] - ride['current']} koltuk kaldı',
                            style: TextStyle(
                              color: isFull ? AppTheme.errorRed : AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isFull ? AppTheme.errorRed : AppTheme.primaryYellow,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: isFull ? null : () {},
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Katıl'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateSharedRideBottomSheet extends StatefulWidget {
  const CreateSharedRideBottomSheet({super.key});

  @override
  State<CreateSharedRideBottomSheet> createState() => _CreateSharedRideBottomSheetState();
}

class _CreateSharedRideBottomSheetState extends State<CreateSharedRideBottomSheet> {
  int _currentStep = 0;
  String from = '';
  String to = '';
  double capacity = 4;
  TimeOfDay time = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 24),
          Text(
            'Yolculuk Oluştur',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep(
                  'Nereden?',
                  TextField(
                    onChanged: (v) => from = v,
                    decoration: InputDecoration(hintText: 'Başlangıç noktası', filled: true, fillColor: AppTheme.lightBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                  ),
                ),
                _buildStep(
                  'Nereye?',
                  TextField(
                    onChanged: (v) => to = v,
                    decoration: InputDecoration(hintText: 'Varış noktası', filled: true, fillColor: AppTheme.lightBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                  ),
                ),
                _buildStep(
                  'Saat ve Kapasite',
                  Column(
                    children: [
                      ListTile(
                        title: const Text('Yolculuk Saati'),
                        trailing: Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () async {
                          final selected = await showTimePicker(context: context, initialTime: time);
                          if (selected != null) setState(() => time = selected);
                        },
                      ),
                      const SizedBox(height: 20),
                      Text('Vito Kapasitesi: ${capacity.toInt()}'),
                      Slider(
                        value: capacity,
                        min: 1,
                        max: 8,
                        divisions: 7,
                        activeColor: AppTheme.primaryYellow,
                        onChanged: (v) => setState(() => capacity = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Geri'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      Navigator.pop(context, {
                        'from': from,
                        'to': to,
                        'date': 'Bugün',
                        'time': time.format(context),
                        'capacity': capacity.toInt(),
                        'current': 1,
                        'price': 100,
                      });
                    }
                  },
                  child: Text(_currentStep < 2 ? 'Devam Et' : 'Yolculuğu Oluştur'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        content,
      ],
    );
  }
}
