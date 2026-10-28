import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/screens/login_screen.dart';
import 'package:kktc_taksim/screens/main_navigation_screen.dart';
import 'package:kktc_taksim/screens/role_selection_screen.dart';
import 'package:kktc_taksim/screens/signup_screen.dart';
import 'package:kktc_taksim/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // google_mobile_ads yalnızca Android ve iOS'ta çalışır; web'de reklamlar kapalı.
  if (!kIsWeb) MobileAds.instance.initialize();
  runApp(const TaxiApp(showAds: !kIsWeb));
}

class TaxiApp extends StatelessWidget {
  /// Banner reklamları kapatmak için (örneğin testlerde) false verilir.
  final bool showAds;

  const TaxiApp({super.key, this.showAds = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KKTC Taksim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Uygulama metinleri şimdilik yalnızca Türkçe; saat/tarih seçici gibi
      // hazır bileşenler de Türkçe görünsün.
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.roleSelection: (context) => const RoleSelectionScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.main: (context) => MainNavigationScreen(showAds: showAds),
      },
    );
  }
}
