import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/screens/explore_screen.dart';
import 'package:kktc_taksim/screens/home_screen.dart';
import 'package:kktc_taksim/screens/my_trips_screen.dart';
import 'package:kktc_taksim/screens/profile_screen.dart';
import 'package:kktc_taksim/screens/shared_ride_screen.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:kktc_taksim/widgets/nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool showAds;

  /// Testler sahte servis verebilir.
  final GeocodingService? geocoding;
  final RoutingService? routing;

  const MainNavigationScreen({super.key, this.showAds = true, this.geocoding, this.routing});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Google'ın resmi test reklam kimliği; yayından önce gerçek kimlikle değiştirilmeli.
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  static const int _homeIndex = 0;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey();
  int _selectedIndex = _homeIndex;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.showAds) _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _callTaxiTo(GeoPlace place) {
    _onItemTapped(_homeIndex);
    _homeKey.currentState?.rideTo(place);
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeScreen(key: _homeKey, geocoding: widget.geocoding, routing: widget.routing),
                MyTripsScreen(onCallTaxi: () => _onItemTapped(_homeIndex)),
                const SharedRideScreen(),
                ExploreScreen(onCallTaxi: _callTaxiTo),
                ProfileScreen(hasActiveRide: () => _homeKey.currentState?.hasActiveRide ?? false),
              ],
            ),
          ),
          if (_isAdLoaded && bannerAd != null)
            SizedBox(
              width: bannerAd.size.width.toDouble(),
              height: bannerAd.size.height.toDouble(),
              child: AdWidget(ad: bannerAd),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
