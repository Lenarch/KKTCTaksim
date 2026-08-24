import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppState { idle, selectingTaxi, searching, driverFound, activeTrip, tripCompleted }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  AppState _currentState = AppState.idle;

  void _onDestinationSelected() {
    Navigator.pop(context); // Close destination bottom sheet
    setState(() {
      _currentState = AppState.selectingTaxi;
    });
    _showTaxiSelectionBottomSheet();
  }

  void _showDestinationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DestinationBottomSheet(onSelected: _onDestinationSelected),
    );
  }

  void _showTaxiSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => TaxiSelectionBottomSheet(
        onConfirm: () {
          Navigator.pop(context);
          _startSearching();
        },
      ),
    );
  }

  void _startSearching() {
    setState(() => _currentState = AppState.searching);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _currentState = AppState.driverFound);
        _showDriverFoundBottomSheet();
      }
    });
  }

  void _showDriverFoundBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => DriverFoundBottomSheet(
        onStart: () {
          Navigator.pop(context);
          setState(() => _currentState = AppState.activeTrip);
          _showActiveTripBottomSheet();
        },
      ),
    );
  }

  void _showActiveTripBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActiveTripBottomSheet(
        onComplete: () {
          Navigator.pop(context);
          setState(() => _currentState = AppState.tripCompleted);
          _showTripCompletedDialog();
        },
      ),
    );
  }

  void _showTripCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TripCompletedDialog(),
    ).then((_) {
      setState(() => _currentState = AppState.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(35.1856, 33.3823),
              initialZoom: 14.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all \u0026 ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  const Marker(
                    point: LatLng(35.1856, 33.3823),
                    width: 60,
                    height: 60,
                    child: Icon(Icons.my_location, color: Colors.blue, size: 30),
                  ),
                  if (_currentState == AppState.idle) ...[
                    _buildTaxiMarker(const LatLng(35.1900, 33.3850)),
                    _buildTaxiMarker(const LatLng(35.1800, 33.3750)),
                  ],
                  if (_currentState == AppState.driverFound || _currentState == AppState.activeTrip)
                    Marker(
                      point: const LatLng(35.1880, 33.3860),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(color: AppTheme.primaryYellow, shape: BoxShape.circle, border: Border.all(width: 2)),
                        child: const Icon(Icons.local_taxi, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (_currentState == AppState.idle) _buildIdleHeader(),
          if (_currentState == AppState.idle) _buildSearchCard(),
          if (_currentState == AppState.searching) _buildSearchingOverlay(),

          // Map Controls
          Positioned(
            right: 20,
            bottom: _currentState == AppState.idle ? 180 : 100,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppTheme.white,
              onPressed: () => _mapController.move(const LatLng(35.1856, 33.3823), 14),
              child: const Icon(Icons.gps_fixed, color: AppTheme.primaryBlack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Merhaba 👋', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                Text('Nereye gitmek istersin?', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const CircleAvatar(radius: 25, backgroundColor: AppTheme.primaryYellow, child: Icon(Icons.person, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: _showDestinationBottomSheet,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
          child: Column(
            children: [
              const Row(children: [Icon(Icons.location_on, color: Colors.blue), SizedBox(width: 15), Text('Mevcut konumun', style: TextStyle(color: AppTheme.grayText))]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(indent: 40)),
              Row(children: [const Icon(Icons.circle, color: AppTheme.errorRed, size: 20), const SizedBox(width: 15), Text('Nereye gitmek istiyorsun?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16))]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryYellow),
            const SizedBox(height: 30),
            Text('Taksi aranıyor...', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Yakındaki sürücülerle eşleştiriliyorsun', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () => setState(() => _currentState = AppState.idle),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size(200, 50)),
              child: const Text('İptal Et'),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildTaxiMarker(LatLng point) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(color: AppTheme.primaryYellow, shape: BoxShape.circle, border: Border.all(width: 2)),
        child: const Icon(Icons.local_taxi, size: 20, color: Colors.black),
      ),
    );
  }
}

// --- Helper Bottom Sheets ---

class DestinationBottomSheet extends StatelessWidget {
  final VoidCallback onSelected;
  const DestinationBottomSheet({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(decoration: InputDecoration(hintText: 'Nereye gitmek istersin?', prefixIcon: const Icon(Icons.search), filled: true, fillColor: AppTheme.lightBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                ListTile(leading: const Icon(Icons.history), title: const Text('Ercan Havalimanı'), onTap: onSelected),
                ListTile(leading: const Icon(Icons.history), title: const Text('Girne Yat Limanı'), onTap: onSelected),
                ListTile(leading: const Icon(Icons.history), title: const Text('Gazimağusa Surlariçi'), onTap: onSelected),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaxiSelectionBottomSheet extends StatefulWidget {
  final VoidCallback onConfirm;
  const TaxiSelectionBottomSheet({super.key, required this.onConfirm});

  @override
  State<TaxiSelectionBottomSheet> createState() => _TaxiSelectionBottomSheetState();
}

class _TaxiSelectionBottomSheetState extends State<TaxiSelectionBottomSheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Senin için taksiler', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTaxiOption(0, 'Ekonomik', '3 dk', '₺120', Icons.directions_car),
          _buildTaxiOption(1, 'Konfor', '5 dk', '₺160', Icons.king_bed),
          _buildTaxiOption(2, 'XL', '8 dk', '₺220', Icons.airport_shuttle),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: widget.onConfirm, child: const Text('TAKSİ ÇAĞIR')),
        ],
      ),
    );
  }

  Widget _buildTaxiOption(int index, String name, String time, String price, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppTheme.primaryYellow : Colors.grey[200]!, width: 2),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppTheme.primaryYellow.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: isSelected ? AppTheme.primaryYellow : AppTheme.grayText),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), Text(time, style: const TextStyle(color: AppTheme.grayText))])),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class DriverFoundBottomSheet extends StatelessWidget {
  final VoidCallback onStart;
  const DriverFoundBottomSheet({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 30, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ahmet Yılmaz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), const Text(' 4.9')]), const Text('Toyota Corolla • 34 ABC 123')])),
              Column(children: [const Text('Varış', style: TextStyle(color: AppTheme.grayText)), const Text('3 dk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Mesaj'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Ara'))),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onStart, child: const Text('YOLCULUĞU BAŞLAT (DEMO)')),
        ],
      ),
    );
  }
}

class ActiveTripBottomSheet extends StatelessWidget {
  final VoidCallback onComplete;
  const ActiveTripBottomSheet({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Yolculuğun devam ediyor', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.access_time, size: 16, color: AppTheme.grayText), const SizedBox(width: 5), const Text('12 dk kaldı', style: TextStyle(color: AppTheme.grayText))]),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              const CircleAvatar(backgroundColor: AppTheme.primaryYellow, child: Icon(Icons.security, color: Colors.black)),
              const SizedBox(width: 15),
              const Text('Güvenlik Araçları', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(onPressed: onComplete, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white, minimumSize: const Size(100, 40)), child: const Text('BİTİR (DEMO)')),
            ],
          ),
        ],
      ),
    );
  }
}

class TripCompletedDialog extends StatelessWidget {
  const TripCompletedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 80),
            const SizedBox(height: 20),
            Text('Yolculuk Tamamlandı', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Toplam Tutar: ₺185,00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 30),
            Text('Yolculuğun nasıl geçti?', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 30))),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Değerlendirmeyi Gönder')),
          ],
        ),
      ),
    );
  }
}
