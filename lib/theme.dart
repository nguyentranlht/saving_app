import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

extension ColorX on Color {
  Color op(double opacity) => withAlpha((opacity * 255).round());
}

/// Bảng màu theo thiết kế (sáng / tối).
class AppColors {
  const AppColors({
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.heroStart,
    required this.heroEnd,
    required this.expense,
    required this.income,
    required this.segment,
    required this.divider,
    required this.chip,
    required this.tipBg,
    required this.isDark,
  });

  final Color bg, card, text, muted, primary, onPrimary;
  final Color heroStart, heroEnd, expense, income, segment, divider, chip, tipBg;
  final bool isDark;

  static const light = AppColors(
    bg: Color(0xFFF2F4F3),
    card: Colors.white,
    text: Color(0xFF14211C),
    muted: Color(0xFF6B7A74),
    primary: Color(0xFF0B5D4B),
    onPrimary: Colors.white,
    heroStart: Color(0xFF0B5D4B),
    heroEnd: Color(0xFF0F6B55),
    expense: Color(0xFFE5594F),
    income: Color(0xFF1E9E6A),
    segment: Color(0xFFE4E9E7),
    divider: Color(0xFFE9EDEB),
    chip: Color(0xFFE4E9E7),
    tipBg: Color(0xFFE3ECFC),
    isDark: false,
  );

  static const dark = AppColors(
    bg: Color(0xFF0D1412),
    card: Color(0xFF17211E),
    text: Color(0xFFF2F6F4),
    muted: Color(0xFF9BAAA4),
    primary: Color(0xFF5FD8AE),
    onPrimary: Color(0xFF0D1412),
    heroStart: Color(0xFF0F6B55),
    heroEnd: Color(0xFF127A61),
    expense: Color(0xFFFF7A70),
    income: Color(0xFF4FD39F),
    segment: Color(0xFF212D29),
    divider: Color(0xFF243029),
    chip: Color(0xFF1F2A27),
    tipBg: Color(0xFF1C2849),
    isDark: true,
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildTheme(AppColors c) {
  final base = ThemeData(
    brightness: c.isDark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: c.isDark ? Brightness.dark : Brightness.light,
    ).copyWith(surface: c.card, primary: c.primary),
    dividerColor: c.divider,
  );
  return base.copyWith(
    textTheme: GoogleFonts.beVietnamProTextTheme(base.textTheme)
        .apply(bodyColor: c.text, displayColor: c.text),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      elevation: 0,
      foregroundColor: c.text,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.text,
      contentTextStyle: TextStyle(color: c.bg),
    ),
  );
}
