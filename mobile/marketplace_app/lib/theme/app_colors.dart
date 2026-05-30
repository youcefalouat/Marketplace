import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────
/// Marketplace Design System — Token-based colors
/// ─────────────────────────────────────────────────
///
/// Usage:  final colors = Theme.of(context).extension<AppColors>()!;
///         Container(color: colors.backgroundPrimary)
///
/// NEVER use Colors.white / Colors.black / Colors.grey etc.
/// ALWAYS use tokens from this extension.

class AppColors extends ThemeExtension<AppColors> {
  // ── Base surfaces ──
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceElevated1;  // cards
  final Color surfaceElevated2;  // modals, dialogs
  final Color surfaceHighlight;  // hover, selected

  // ── Borders ──
  final Color border;
  final Color borderSubtle;
  final Color divider;

  // ── Text hierarchy ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnPrimary;

  // ── Brand: Primary (blue) ──
  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color primaryDisabled;
  final Color primaryMuted;      // tinted background

  // ── Brand: Accent (green — deals only) ──
  final Color accent;
  final Color accentHover;
  final Color accentPressed;
  final Color accentDisabled;
  final Color accentMuted;       // tinted background

  // ── Semantic ──
  final Color warning;
  final Color warningMuted;
  final Color error;
  final Color errorMuted;

  // ── Misc ──
  final Color starRating;
  final Color shimmer;
  final Color imagePlaceholder;
  final Color navBarBackground;
  final Color shadowColor;

  const AppColors({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceElevated1,
    required this.surfaceElevated2,
    required this.surfaceHighlight,
    required this.border,
    required this.borderSubtle,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.primaryDisabled,
    required this.primaryMuted,
    required this.accent,
    required this.accentHover,
    required this.accentPressed,
    required this.accentDisabled,
    required this.accentMuted,
    required this.warning,
    required this.warningMuted,
    required this.error,
    required this.errorMuted,
    required this.starRating,
    required this.shimmer,
    required this.imagePlaceholder,
    required this.navBarBackground,
    required this.shadowColor,
  });

  // ─── DARK MODE ───
  static const dark = AppColors(
    // Base surfaces (warm dark grey scale, NO pure black)
    backgroundPrimary:   Color(0xFF0F1115),
    backgroundSecondary: Color(0xFF1A1D23),
    surface:             Color(0xFF22262E),
    surfaceElevated1:    Color(0xFF1E2228),  // cards — slightly above bg
    surfaceElevated2:    Color(0xFF282D36),  // modals, sheets
    surfaceHighlight:    Color(0xFF2A2F38),  // selected/hover

    // Borders
    border:        Color(0xFF2E3340),
    borderSubtle:  Color(0xFF252930),
    divider:       Color(0xFF252930),

    // Text (contrast ratios vs #0F1115)
    textPrimary:   Color(0xFFEAEDF2),  // 15.2:1 ✅
    textSecondary: Color(0xFF9DA3AE),  //  5.8:1 ✅
    textTertiary:  Color(0xFF6B7280),  //  3.5:1 (decorative only)
    textOnPrimary: Color(0xFFFAFAFA),  // on buttons

    // Primary — desaturated blue
    primary:         Color(0xFF5B8DEF),
    primaryHover:    Color(0xFF6E9CF2),
    primaryPressed:  Color(0xFF4A7ADB),
    primaryDisabled: Color(0xFF3A4A66),
    primaryMuted:    Color(0xFF1E2A42),  // tinted bg

    // Accent — harmonized green (DEALS ONLY)
    accent:         Color(0xFF3ECF8E),
    accentHover:    Color(0xFF52D89D),
    accentPressed:  Color(0xFF2EBB7D),
    accentDisabled: Color(0xFF2A5A45),
    accentMuted:    Color(0xFF1A3329),

    // Semantic
    warning:      Color(0xFFF0A94E),
    warningMuted: Color(0xFF3D2F1A),
    error:        Color(0xFFEF5B5B),
    errorMuted:   Color(0xFF3D1F1F),

    // Misc
    starRating:       Color(0xFFF5A623),
    shimmer:          Color(0xFF252930),
    imagePlaceholder: Color(0xFF1E2228),
    navBarBackground: Color(0xFF161A20),  // distinct from backgroundPrimary
    shadowColor:      Color(0x40000000),
  );

  // ─── LIGHT MODE ───
  static const light = AppColors(
    backgroundPrimary:   Color(0xFFF7F8FA),
    backgroundSecondary: Color(0xFFFFFFFF),
    surface:             Color(0xFFFFFFFF),
    surfaceElevated1:    Color(0xFFFFFFFF),
    surfaceElevated2:    Color(0xFFFFFFFF),
    surfaceHighlight:    Color(0xFFF0F2F5),

    border:        Color(0xFFE5E7EB),
    borderSubtle:  Color(0xFFF0F0F2),
    divider:       Color(0xFFE5E7EB),

    textPrimary:   Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textTertiary:  Color(0xFF9CA3AF),
    textOnPrimary: Color(0xFFFAFAFA),

    primary:         Color(0xFF2563EB),
    primaryHover:    Color(0xFF3B75F0),
    primaryPressed:  Color(0xFF1D4FCC),
    primaryDisabled: Color(0xFFB0C4F0),
    primaryMuted:    Color(0xFFE8EEFB),

    accent:         Color(0xFF16A34A),
    accentHover:    Color(0xFF1DB954),
    accentPressed:  Color(0xFF138A3E),
    accentDisabled: Color(0xFFA8D9B8),
    accentMuted:    Color(0xFFE6F4EC),

    warning:      Color(0xFFD97706),
    warningMuted: Color(0xFFFEF3C7),
    error:        Color(0xFFDC2626),
    errorMuted:   Color(0xFFFEE2E2),

    starRating:       Color(0xFFF5A623),
    shimmer:          Color(0xFFE5E7EB),
    imagePlaceholder: Color(0xFFF0F2F5),
    navBarBackground: Color(0xFFFFFFFF),
    shadowColor:      Color(0x1A000000),
  );

  @override
  AppColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? surface,
    Color? surfaceElevated1,
    Color? surfaceElevated2,
    Color? surfaceHighlight,
    Color? border,
    Color? borderSubtle,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnPrimary,
    Color? primary,
    Color? primaryHover,
    Color? primaryPressed,
    Color? primaryDisabled,
    Color? primaryMuted,
    Color? accent,
    Color? accentHover,
    Color? accentPressed,
    Color? accentDisabled,
    Color? accentMuted,
    Color? warning,
    Color? warningMuted,
    Color? error,
    Color? errorMuted,
    Color? starRating,
    Color? shimmer,
    Color? imagePlaceholder,
    Color? navBarBackground,
    Color? shadowColor,
  }) {
    return AppColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      surface: surface ?? this.surface,
      surfaceElevated1: surfaceElevated1 ?? this.surfaceElevated1,
      surfaceElevated2: surfaceElevated2 ?? this.surfaceElevated2,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryDisabled: primaryDisabled ?? this.primaryDisabled,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentPressed: accentPressed ?? this.accentPressed,
      accentDisabled: accentDisabled ?? this.accentDisabled,
      accentMuted: accentMuted ?? this.accentMuted,
      warning: warning ?? this.warning,
      warningMuted: warningMuted ?? this.warningMuted,
      error: error ?? this.error,
      errorMuted: errorMuted ?? this.errorMuted,
      starRating: starRating ?? this.starRating,
      shimmer: shimmer ?? this.shimmer,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      backgroundPrimary: Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary: Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated1: Color.lerp(surfaceElevated1, other.surfaceElevated1, t)!,
      surfaceElevated2: Color.lerp(surfaceElevated2, other.surfaceElevated2, t)!,
      surfaceHighlight: Color.lerp(surfaceHighlight, other.surfaceHighlight, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primaryDisabled: Color.lerp(primaryDisabled, other.primaryDisabled, t)!,
      primaryMuted: Color.lerp(primaryMuted, other.primaryMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentDisabled: Color.lerp(accentDisabled, other.accentDisabled, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningMuted: Color.lerp(warningMuted, other.warningMuted, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorMuted: Color.lerp(errorMuted, other.errorMuted, t)!,
      starRating: Color.lerp(starRating, other.starRating, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
      imagePlaceholder: Color.lerp(imagePlaceholder, other.imagePlaceholder, t)!,
      navBarBackground: Color.lerp(navBarBackground, other.navBarBackground, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

/// ─────────────────────────────────────────────────
/// Layout tokens — spacing, radii, elevation
/// ─────────────────────────────────────────────────
class AppLayout {
  AppLayout._();

  // Spacing scale (Material-aligned)
  static const double spacing2  = 2;
  static const double spacing4  = 4;
  static const double spacing6  = 6;
  static const double spacing8  = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;

  // Border radii
  static const double radiusSmall  = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge  = 16;
  static const double radiusXL     = 20;
  static const double radiusFull   = 999;

  // Card padding
  static const double cardPadding      = 12;
  static const double cardPaddingLarge = 16;
  static const double screenPadding   = 16;

  // Helpers
  static BorderRadius get borderRadiusSmall  => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge  => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXL     => BorderRadius.circular(radiusXL);
}
