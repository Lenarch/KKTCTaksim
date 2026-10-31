import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/legal_links.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/core/validators.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/screens/otp_screen.dart';
import 'package:kktc_taksim/widgets/auth_header.dart';
import 'package:kktc_taksim/widgets/loading_button.dart';
import 'package:kktc_taksim/widgets/phone_field.dart';

/// Ad ve telefon numarasıyla kayıt; numara SMS koduyla doğrulanır.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(phoneNumber: phone, name: _nameController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

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
                const SizedBox(height: AppSpacing.lg),
                AuthHeader(title: l10n.createAccount, subtitle: l10n.signupSubtitle),
                const SizedBox(height: AppSpacing.xxxl),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) => Validators.required(l10n, value),
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PhoneField(
                  controller: _phoneController,
                  validator: (value) => Validators.phone(l10n, value),
                  onSubmitted: _submit,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                LoadingButton(loading: _busy, onPressed: _submit, label: l10n.signUp),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l10n.termsPrefix, style: mutedStyle),
                      GestureDetector(
                        onTap: () async {
                          final message = l10n.cannotOpen;
                          final opened = await openLegalPage(termsOfUseUrl);
                          if (!opened && context.mounted) showMessage(context, message);
                        },
                        child: Text(
                          l10n.termsOfUse,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(l10n.termsSuffix, style: mutedStyle),
                    ],
                  ),
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
