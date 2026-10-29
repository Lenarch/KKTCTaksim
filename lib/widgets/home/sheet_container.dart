import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_tokens.dart';

/// Modal bottom sheet içerikleri için ortak çerçeve: tutma çubuğu, kenar boşlukları,
/// alt güvenli alan ve klavye yüksekliği.
class SheetContainer extends StatelessWidget {
  final Widget child;
  final double? heightFactor;

  const SheetContainer({super.key, required this.child, this.heightFactor});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl + mediaQuery.viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: heightFactor == null ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Flexible: içerik ekrana sığmazsa kaydırılabilir bir child taşmadan küçülür.
            if (heightFactor == null) Flexible(child: child) else Expanded(child: child),
          ],
        ),
      ),
    );

    if (heightFactor == null) return content;
    return SizedBox(height: mediaQuery.size.height * heightFactor!, child: content);
  }
}
