import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';

/// Sunucu yanıtı beklenirken dönen gösterge gösteren ve tekrar basılamayan ana buton.
class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String label;

  const LoadingButton({super.key, required this.loading, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryBlack),
            )
          : Text(label),
    );
  }
}
