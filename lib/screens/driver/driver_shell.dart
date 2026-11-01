import 'package:flutter/material.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/driver_repository.dart';
import 'package:kktc_taksim/screens/driver/driver_home_screen.dart';
import 'package:kktc_taksim/screens/driver/driver_registration_screen.dart';

/// Şoför modunun girişi: kaydı yoksa kayıt formu, varsa şoför ana ekranı.
class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  late final Stream<DriverProfile?> _profile = Backend.instance.drivers.watchProfile();
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DriverProfile?>(
      stream: _profile,
      builder: (context, snapshot) {
        // İlk belge gelmeden kayıt formu gösterilmesin (kayıtlı şoför bir an formu görürdü).
        if (snapshot.connectionState == ConnectionState.waiting && !_loaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        _loaded = true;
        final profile = snapshot.data;
        if (profile == null) return const DriverRegistrationScreen();
        return DriverHomeScreen(profile: profile);
      },
    );
  }
}
