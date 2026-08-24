import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryYellow = Color(0xFFFFD400);
  static const Color primaryBlack = Color(0xFF111111);
  static const Color darkBackground = Color(0xFF181818);
  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grayText = Color(0xFF757575);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF43A047);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryYellow,
        onPrimary: primaryBlack,
        secondary: primaryBlack,
        onSecondary: primaryYellow,
        surface: white,
        onSurface: primaryBlack,
        background: lightBackground,
        onBackground: primaryBlack,
        error: errorRed,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryBlack),
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: primaryBlack),
        bodyLarge: GoogleFonts.poppins(color: primaryBlack),
        bodyMedium: GoogleFonts.poppins(color: grayText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: primaryBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
        ),
        iconTheme: const IconThemeData(color: primaryBlack),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: primaryBlack,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shadowColor: primaryBlack.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryBlack,
        selectedItemColor: primaryYellow,
        unselectedItemColor: grayText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        onPrimary: primaryBlack,
        secondary: primaryYellow,
        onSecondary: primaryBlack,
        surface: darkBackground,
        onSurface: white,
        background: Colors.black,
        onBackground: white,
      ),
      scaffoldBackgroundColor: Colors.black,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      // Add more dark theme customizations as needed
    );
  }
}
