import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const fedsOrange = Color(0xFFFF9F1C);
const fedsOrangeLight = Color(0xFFFF6B6B);
const bgDark = Color(0xFF0B0C10);
const cardBg = Color(0xFF161B22);
const cardBorder = Color(0x14FFFFFF);
const textPrimary = Color(0xFFF0F6FC);
const textSecondary = Color(0xFF8B949E);
const statusOnline = Color(0xFF2EC4B6);
const statusRunning = fedsOrange;
const statusOffline = Color(0xFFE63946);
const statusInfo = Color(0xFF4EA8DE);
const statusIos = Color(0xFFA8D8F0);
const consoleGreen = Color(0xFF4DFD52);
const consoleBlue = statusInfo;
const consoleRed = statusOffline;

const primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [fedsOrange, fedsOrangeLight],
);

const stopGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [statusOffline, Color(0xFFB21E29)],
);

const iosGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [statusInfo, Color(0xFF1A6FA8)],
);

ThemeData buildTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: bgDark,
    colorScheme: base.colorScheme.copyWith(
      primary: fedsOrange,
      secondary: fedsOrangeLight,
      surface: cardBg,
    ),
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: cardBorder),
      ),
    ),
    dividerColor: cardBorder,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x55000000),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: fedsOrange, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
      hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
    ),
  );
}
