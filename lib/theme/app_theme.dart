import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0B0B0F);
  static const Color card = Color(0xFF14141B);
  static const Color orange = Color(0xFFFF8A00);
  static const Color text = Color(0xFFF3F3F7);
  static const Color muted = Color(0xFF9A9AA6);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: orange,
        secondary: orange,
        surface: card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      dividerColor: Colors.white10,
    );
  }
}
