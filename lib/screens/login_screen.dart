import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/core/validators.dart';
import 'package:kktc_taksim/widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: Gerçek kimlik doğrulama servisi bağlanınca burada çağrılacak.
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
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
                const AuthHeader(title: 'Hoş Geldiniz', subtitle: 'Devam etmek için giriş yapın'),
                const SizedBox(height: AppSpacing.xxxl),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _isPasswordVisible ? 'Şifreyi gizle' : 'Şifreyi göster',
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => showComingSoon(context, 'Şifre sıfırlama'),
                    child: const Text('Şifremi Unuttum'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Giriş Yap'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hesabınız yok mu?',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                      child: const Text('Kayıt Ol'),
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
