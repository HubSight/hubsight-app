import 'package:flutter/material.dart';

/// HubSight Brand & Design System Colors
/// Exact 1:1 mapping from WebApp `tailwind.config.js` and `index.css`:
/// - `slate-950`: #000000 (OLED pitch-black background)
/// - `slate-900`: #09090b (Pitch-black charcoal card / container / modal / sidebar)
/// - `slate-850`: #111113 (Intermediate deep charcoal)
/// - `slate-800`: #18181b (Deep charcoal surface / inputs / hover / button outline)
/// - `slate-700`: #27272a (Crisp dark border - Zinc 800)
/// - `slate-500`: #71717a (Muted text / placeholder)
/// - `slate-400`: #a1a1aa / #94a3b8 (Secondary labels / icons)
/// - `slate-100`: #f4f4f5 (Primary crisp text)
/// - `orange-600`: #ea580c (Official HubSight Brand Accent --accent-color)
/// - `orange-500`: #f97316 (Primary light / focus ring)
class HubSightColors {
  HubSightColors._();

  // Backgrounds
  static const Color bgDark = Color(0xFF000000); // slate-950
  static const Color cardDark = Color(0xFF09090B); // slate-900
  static const Color surfaceElevated = Color(0xFF111113); // slate-850
  static const Color surfaceDark = Color(0xFF18181B); // slate-800

  // Borders
  static const Color borderDark = Color(0xFF27272A); // slate-700 (crisp zinc-800)
  static const Color borderSubtle = Color(0xFF18181B); // slate-800

  // Brand Accent (Orange)
  static const Color primary = Color(0xFFEA580C); // orange-600 (official)
  static const Color primaryHover = Color(0xFFC2410C); // orange-700
  static const Color primaryLight = Color(0xFFF97316); // orange-500
  static const Color primaryBg = Color(0x26EA580C); // orange-950/15%

  // Typography & Neutrals
  static const Color textPrimary = Color(0xFFF4F4F5); // slate-100
  static const Color textSecondary = Color(0xFFA1A1AA); // slate-400
  static const Color textMuted = Color(0xFF71717A); // slate-500

  // Status & Feedback
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color errorBg = Color(0x33450A0A); // red-950/20%
  static const Color errorBorder = Color(0x667F1D1D); // red-800/40%
  static const Color errorText = Color(0xFFFCA5A5); // red-300
  static const Color success = Color(0xFF22C55E); // green-500
  static const Color successBg = Color(0x2614532D); // green-950/15%
}

/// HubSight Exact Border Radiuses
/// From webapp `tailwind.config.js`:
/// - `xs`, `sm`: 2px
/// - `DEFAULT`: 3px
/// - `md`, `lg`: 4px
/// - `xl`: 5px
/// - `2xl`, `3xl`: 6px
/// - `card`: 12px / 16px
/// - `full`: 9999px
class HubSightRadius {
  HubSightRadius._();

  static const double xs = 2.0;
  static const double sm = 2.0;
  static const double def = 3.0;
  static const double md = 4.0;
  static const double lg = 4.0;
  static const double xl = 6.0;
  static const double xxl = 8.0;
  static const double card = 12.0;
  static const double cardLg = 16.0;
  static const double sheet = 24.0;
  static const double full = 9999.0;

  static final BorderRadius roundedSm = BorderRadius.circular(sm);
  static final BorderRadius roundedMd = BorderRadius.circular(md);
  static final BorderRadius roundedLg = BorderRadius.circular(lg);
  static final BorderRadius roundedXl = BorderRadius.circular(xl);
  static final BorderRadius roundedXxl = BorderRadius.circular(xxl);
  static final BorderRadius roundedCard = BorderRadius.circular(card);
  static final BorderRadius roundedCardLg = BorderRadius.circular(cardLg);
  static const BorderRadius roundedSheet = BorderRadius.vertical(top: Radius.circular(sheet));
  static final BorderRadius roundedFull = BorderRadius.circular(full);
}

/// AppTheme definition unifying Mobile UI with HubSight WebApp Dark Theme
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: HubSightColors.bgDark,
      canvasColor: HubSightColors.cardDark,
      cardColor: HubSightColors.cardDark,
      dividerColor: HubSightColors.borderDark,
      colorScheme: const ColorScheme.dark(
        primary: HubSightColors.primary,
        onPrimary: Colors.white,
        secondary: HubSightColors.primaryLight,
        onSecondary: Colors.white,
        surface: HubSightColors.cardDark,
        onSurface: HubSightColors.textPrimary,
        error: HubSightColors.error,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: HubSightColors.cardDark,
        foregroundColor: HubSightColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: HubSightColors.cardDark,
        elevation: 0,
        shape: Border(
          right: BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
      ),
      cardTheme: CardThemeData(
        color: HubSightColors.cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCard,
          side: const BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: HubSightColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCardLg,
          side: const BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: HubSightColors.cardDark,
        modalBackgroundColor: HubSightColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedSheet,
          side: BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HubSightColors.surfaceDark,
        contentTextStyle: const TextStyle(color: HubSightColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedXl,
          side: const BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HubSightColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: HubSightRadius.roundedXl,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: HubSightColors.surfaceDark,
          foregroundColor: HubSightColors.textPrimary,
          elevation: 0,
          side: const BorderSide(color: HubSightColors.borderDark, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: HubSightRadius.roundedXl,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HubSightColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(
          color: HubSightColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: HubSightColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: HubSightColors.textMuted,
        suffixIconColor: HubSightColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: HubSightRadius.roundedXl,
          borderSide: const BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: HubSightRadius.roundedXl,
          borderSide: const BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: HubSightRadius.roundedXl,
          borderSide: const BorderSide(color: HubSightColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: HubSightRadius.roundedXl,
          borderSide: const BorderSide(color: HubSightColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: HubSightRadius.roundedXl,
          borderSide: const BorderSide(color: HubSightColors.error, width: 1.5),
        ),
      ),
    );
  }
}
