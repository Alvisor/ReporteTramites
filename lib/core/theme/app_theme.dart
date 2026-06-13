import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.fondo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.acento,
        primary: AppColors.oscuro,
        surface: AppColors.fondo,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.oscuro,
        displayColor: AppColors.oscuro,
      ),
    );
  }

  /// Estilo para títulos destacados (placas, montos) con la fuente serif Fraunces.
  static TextStyle serif({
    double size = 18,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.oscuro,
      );
}
