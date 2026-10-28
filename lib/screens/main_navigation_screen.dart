import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kktc_taksim/screens/explore_screen.dart';
import 'package:kktc_taksim/screens/home_screen.dart';
import 'package:kktc_taksim/screens/my_trips_screen.dart';
import 'package:kktc_taksim/screens/profile_screen.dart';
import 'package:kktc_taksim/screens/shared_ride_screen.dart';
import 'package:kktc_taksim/widgets/nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool showAds;

  const MainNavigationScreen({super.key, this.showAds = true});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Google'ın resmi test reklam kimliği; yayından önce gerçek kimlikle değiştirilmeli.
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  int _selectedIndex = 0;
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
                const HomeScreen(),
                MyTripsScreen(onCallTaxi: () => _onItemTapped(0)),
                const SharedRideScreen(),
                const ExploreScreen(),
                const ProfileScreen(),
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
