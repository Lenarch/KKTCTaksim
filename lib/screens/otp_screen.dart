import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/widgets/auth_header.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _codeLength = 4;

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_codeLength, (_) => FocusNode());

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

  void _verify() {
    // TODO: Kod sunucuda doğrulanacak; şimdilik her 4 haneli kod kabul ediliyor.
    // Messenger, eski ekran kapanmadan önce alınır; uygulama genelindeki messenger
    // olduğu için SnackBar yeni ekranda da görünür.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Doğrulama başarılı! Hoş geldiniz.')),
    );
  }

  void _resend() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kod ${widget.phoneNumber} numarasına tekrar gönderildi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                title: 'Doğrulama Kodu',
                subtitle: '${widget.phoneNumber} numarasına gönderilen $_codeLength haneli kodu giriniz.',
              ),
              const SizedBox(height: AppSpacing.huge),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (index) {
                  return SizedBox(
                    width: 64,
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
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              ElevatedButton(
                onPressed: _isCodeComplete ? _verify : null,
                child: const Text('Doğrula'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Kod gelmedi mi?',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: _resend,
                      child: const Text('Tekrar Gönder'),
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
