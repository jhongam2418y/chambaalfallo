import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBrown = Color(0xFF150800);
  static const Color mediumBrown = Color(0xFF2D1200);
  static const Color cardDark = Color(0xFF220E00);
  static const Color cardMedium = Color(0xFF3A1800);
  static const Color primaryOrange = Color(0xFFE8720A);
  static const Color gold = Color(0xFFFFB020);
  static const Color lightGold = Color(0xFFFFD860);
  static const Color cream = Color(0xFFFFF0D0);
  static const Color textLight = Color(0xFFFFF8E8);
  static const Color success = Color(0xFF56C568);
  static const Color danger = Color(0xFFE53935);
  static const Color kitchenBlue = Color(0xFF29B6F6);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: primaryOrange,
          secondary: gold,
          surface: mediumBrown,
          onPrimary: Colors.white,
          onSecondary: darkBrown,
          onSurface: textLight,
        ),
        scaffoldBackgroundColor: darkBrown,
        appBarTheme: const AppBarTheme(
          backgroundColor: mediumBrown,
          foregroundColor: textLight,
          centerTitle: true,
          elevation: 4,
          titleTextStyle: TextStyle(
            color: gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: gold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            elevation: 6,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: gold),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gold.withOpacity(0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryOrange, width: 2),
          ),
          labelStyle: const TextStyle(color: gold),
          hintStyle: TextStyle(color: textLight.withOpacity(0.4)),
          prefixIconColor: gold,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: gold,
          unselectedLabelColor: textLight.withOpacity(0.6),
          indicatorColor: primaryOrange,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 8,
        ),
        dividerColor: Color(0x33FFB020),
        chipTheme: ChipThemeData(
          backgroundColor: cardMedium,
          selectedColor: primaryOrange,
          labelStyle: const TextStyle(color: textLight),
          side: BorderSide(color: gold.withOpacity(0.3)),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textLight, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: gold),
          bodyLarge: TextStyle(color: textLight),
          bodyMedium: TextStyle(color: cream),
          labelLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold),
        ),
      );
}
