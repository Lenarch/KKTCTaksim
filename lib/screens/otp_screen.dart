import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/widgets/auth_header.dart';
import 'package:kktc_taksim/widgets/loading_button.dart';

/// SMS kodunu doğrular. Kod [phoneNumber]'a önceki ekranda gönderilmiş olmalı.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  /// Kayıttan geliniyorsa kullanıcının adı; doğrulamadan sonra profile yazılır.
  final String? name;

  const OtpScreen({super.key, required this.phoneNumber, this.name});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final int _codeLength = Backend.instance.auth.codeLength;
  late final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes = List.generate(_codeLength, (_) => FocusNode());

  bool _busy = false;

  bool get _isCodeComplete => _controllers.every((c) => c.text.isNotEmpty);

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    final l10n = context.l10n;
    // Messenger, eski ekran kapanmadan önce alınır; uygulama genelindeki messenger
    // olduğu için SnackBar yeni ekranda da görünür.
    final messenger = ScaffoldMessenger.of(context);
    final auth = Backend.instance.auth;
    setState(() => _busy = true);
    try {
      await auth.verifyCode(_controllers.map((c) => c.text).join());
      final name = widget.name;
      if (name != null) await auth.updateName(name);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showMessage(context, e.code.label(l10n));
      return;
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
    messenger.showSnackBar(SnackBar(content: Text(l10n.verificationSuccess)));
  }

  Future<void> _resend() async {
    final l10n = context.l10n;
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
    try {
      await Backend.instance.auth.sendCode(widget.phoneNumber);
      if (mounted) showMessage(context, l10n.codeResent(widget.phoneNumber));
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.code.label(l10n));
    }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              AuthHeader(
                title: l10n.verificationCode,
                subtitle: l10n.enterCode(widget.phoneNumber, _codeLength),
              ),
              const SizedBox(height: AppSpacing.huge),
              Row(
                children: List.generate(_codeLength, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      autofocus: index == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 1,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (value) => _onDigitChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              LoadingButton(
                loading: _busy,
                onPressed: _isCodeComplete ? _verify : null,
                label: l10n.verify,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Column(
                  children: [
                    Text(
                      l10n.didntGetCode,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: _resend,
                      child: Text(l10n.resend),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
