import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/core/validators.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/driver_repository.dart';
import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/services/app_settings.dart';
import 'package:kktc_taksim/widgets/auth_header.dart';
import 'package:kktc_taksim/widgets/loading_button.dart';

/// İlk kez şoför moduna girene ad, plaka ve araç bilgisini sorar. Şimdilik onaysız
/// (belge kontrolü yayından önce eklenecek; docs/UYARILAR.md).
class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: Backend.instance.auth.currentUser?.name ?? '');
  final TextEditingController _plate = TextEditingController();
  final TextEditingController _car = TextEditingController();
  CarColor _color = CarColor.white;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _plate.dispose();
    _car.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await Backend.instance.drivers.register(DriverProfile(
        name: _name.text,
        plate: _plate.text,
        car: _car.text,
        carColor: _color,
      ));
    } catch (e) {
      debugPrint('Şoför kaydı başarısız: $e');
      if (mounted) showMessage(context, l10n.actionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switchToPassenger() async {
    await AppSettings.instance.setRole(AppRole.passenger);
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        actions: [TextButton(onPressed: _switchToPassenger, child: Text(l10n.switchToPassenger))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(title: l10n.driverRegisterTitle, subtitle: l10n.driverRegisterSubtitle),
                const SizedBox(height: AppSpacing.xxl),
                TextFormField(
                  controller: _name,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.driverNameLabel, counterText: ''),
                  validator: (v) => Validators.required(l10n, v),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _plate,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l10n.plateFieldLabel, hintText: 'ABC 123', counterText: ''),
                  validator: (v) => Validators.required(l10n, v),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _car,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.carModelLabel, hintText: 'Toyota Corolla', counterText: ''),
                  validator: (v) => Validators.required(l10n, v),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.carColorLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<CarColor>(
                  segments: [
                    for (final color in CarColor.values)
                      ButtonSegment(
                        value: color,
                        label: Text(color.label(l10n)),
                        icon: Icon(Icons.circle, color: color.swatch, size: 14),
                      ),
                  ],
                  selected: {_color},
                  onSelectionChanged: (s) => setState(() => _color = s.first),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                LoadingButton(loading: _busy, onPressed: _save, label: l10n.saveDriver),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
