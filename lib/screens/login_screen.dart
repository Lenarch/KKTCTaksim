import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/core/validators.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/screens/otp_screen.dart';
import 'package:kktc_taksim/widgets/auth_header.dart';
import 'package:kktc_taksim/widgets/loading_button.dart';
import 'package:kktc_taksim/widgets/phone_field.dart';

/// Telefon numarasıyla giriş: numaraya SMS kodu gönderilir, kod doğrulanınca ana sayfaya geçilir.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final phone = _phoneController.text.trim();
    setState(() => _busy = true);
    try {
      await Backend.instance.auth.sendCode(phone);
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.code.label(l10n));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => OtpScreen(phoneNumber: phone)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_taxi_rounded, size: 72, color: AppTheme.primaryBlack),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AuthHeader(title: l10n.welcome, subtitle: l10n.loginSubtitle),
                const SizedBox(height: AppSpacing.xxxl),
                PhoneField(
                  controller: _phoneController,
                  autofocus: true,
                  validator: (value) => Validators.phone(l10n, value),
                  onSubmitted: _submit,
                ),
                const SizedBox(height: AppSpacing.xxl),
                LoadingButton(loading: _busy, onPressed: _submit, label: l10n.sendCode),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.noAccount,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                      child: Text(l10n.signUp),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
