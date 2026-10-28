import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kktc_taksim/core/app_tokens.dart';

class AppTheme {
  AppTheme._();

  // Brand Colors
  static const Color primaryYellow = Color(0xFFFFD400);
  static const Color primaryBlack = Color(0xFF111111);
  static const Color darkBackground = Color(0xFF0B0B0B);
  static const Color darkSurface = Color(0xFF1C1C1C);
  static const Color darkSurfaceHigh = Color(0xFF2A2A2A);
  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grayText = Color(0xFF757575);
  static const Color grayTextDark = Color(0xFFB0B0B0);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF43A047);
  static const Color locationBlue = Color(0xFF1E88E5);
  static const Color ratingAmber = Color(0xFFFFC107);

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryYellow,
      onPrimary: primaryBlack,
      secondary: isDark ? primaryYellow : primaryBlack,
      onSecondary: isDark ? primaryBlack : primaryYellow,
      error: errorRed,
      onError: white,
      surface: isDark ? darkSurface : white,
      onSurface: isDark ? white : primaryBlack,
      onSurfaceVariant: isDark ? grayTextDark : grayText,
      surfaceContainerHighest: isDark ? darkSurfaceHigh : lightBackground,
      outline: isDark ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
      outlineVariant: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
    );

    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.poppinsTextTheme(baseTextTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final fieldRadius = BorderRadius.circular(AppRadius.lg);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? darkBackground : lightBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: primaryBlack,
          disabledBackgroundColor: colorScheme.outlineVariant,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: fieldRadius),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: primaryYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 2,
        shadowColor: primaryBlack.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      tabBarTheme: TabBarThemeData(
        indicatorColor: primaryYellow,
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      chipTheme: ChipThemeData(
        selectedColor: primaryYellow,
        backgroundColor: colorScheme.surface,
        side: BorderSide.none,
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryYellow,
        thumbColor: primaryYellow,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primaryYellow),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
