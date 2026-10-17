import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF4CAF50);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
