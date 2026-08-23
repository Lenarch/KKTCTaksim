import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';

class SharedRideScreen extends StatefulWidget {
  const SharedRideScreen({super.key});

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  final List<Map<String, dynamic>> _rides = [
    {
      'destination': 'Lefkoşa Ercan Havalimanı',
      'date': '24.08.2026',
      'time': '14:30',
      'capacity': 8,
      'current': 3,
    },
    {
      'destination': 'Girne Yat Limanı',
      'date': '25.08.2026',
      'time': '10:00',
      'capacity': 8,
      'current': 5,
    },
  ];

  void _showCreateRideDialog() {
    String destination = '';
    double capacity = 8;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yeni Paylaşımlı Yolculuk Oluştur',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nereye gitmek istiyorsunuz?',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => destination = val,
                  ),
                  const SizedBox(height: 16),
                  Text('Vito Yolcu Kapasitesi: ${capacity.toInt()} Kişi'),
                  Slider(
                    value: capacity,
                    min: 1,
                    max: 8,
                    divisions: 7,
                    label: capacity.toInt().toString(),
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) {
                      setModalState(() {
                        capacity = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _rides.add({
                                'destination': destination,
                                'date': 'Bugün',
                                'time': 'Şimdi',
                                'capacity': capacity.toInt(),
                                'current': 1,
                              });
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Grup Oluştur'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylaşımlı Yolculuk Grupları'),
      ),
      body: ListView.builder(
        itemCount: _rides.length,
        itemBuilder: (context, index) {
          final ride = _rides[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryGreen,
                child: Icon(Icons.directions_car, color: Colors.white),
              ),
              title: Text(ride['destination']),
              subtitle: Text('${ride['date']} - ${ride['time']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${ride['current']}/${ride['capacity']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const Text('Yolcu'),
                ],
              ),
              onTap: () {
                // Gruba katılma mantığı buraya gelecek
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRideDialog,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Grup Oluştur'),
      ),
    );
  }
}
