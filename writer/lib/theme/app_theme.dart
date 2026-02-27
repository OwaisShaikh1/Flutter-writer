import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors (Strictly Black and White)
  static Color lightPrimary(Color customColor) => customColor;      // User can still choose, but default will be black
  static const Color lightOnPrimary = Color(0xFFFFFFFF);            // Pure white
  static const Color lightSecondary = Color(0xFF000000);            // Pure black
  static const Color lightOnSecondary = Color(0xFFFFFFFF);          // Pure white
  static const Color lightSurface = Color(0xFFFFFFFF);              // Pure white
  static Color lightOnSurface(Color customColor) => const Color(0xFF000000); // Strictly black text
  static const Color lightError = Color(0xFFB00020);                // Keep error red
  static const Color lightOnError = Color(0xFFFFFFFF);              // Pure white
  
  // Dark Mode Colors (Strictly Black and White)
  static Color darkPrimary(Color customColor) {
    // If black is selected, use white in dark mode for visibility
    if (customColor.value == 0xFF000000) return const Color(0xFFFFFFFF);
    return customColor;
  }
  static const Color darkOnPrimary = Color(0xFF000000);             // Black for contrast on light primary
  static const Color darkSecondary = Color(0xFFFFFFFF);             // Pure white
  static const Color darkOnSecondary = Color(0xFF000000);           // Pure black
  static const Color darkSurface = Color(0xFF000000);               // Pure Black (OLED friendly)
  static const Color darkOnSurface = Color(0xFFFFFFFF);             // Pure White text
  static const Color darkError = Color(0xFFCF6679);                 // Light red for errors
  static const Color darkOnError = Color(0xFF000000);               // Pure black
  
  // Literature Type Colors (Keeping for icons/badges as requested)
  static const Color drama = Color(0xFFFF5252);     // Red
  static const Color poetry = Color(0xFF7C4DFF);    // Deep Purple
  static const Color novel = Color(0xFF448AFF);     // Blue
  static const Color article = Color(0xFF00BFA5);   // Teal
  static const Color other = Color(0xFF757575);     // Grey

  // Shared Monochrome Shades
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF333333);
  static const Color mediumGrey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFF999999);
  static const Color veryLightGrey = Color(0xFFCCCCCC);
  static const Color ultraLightGrey = Color(0xFFE0E0E0);
  static const Color almostWhite = Color(0xFFF5F5F5);

  static Color _lightenColor(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 0.9));
    return hslLight.toColor();
  }
}

class AppTheme {
  static ColorScheme lightColorScheme(Color customColor) => ColorScheme.light(
    primary: AppColors.lightPrimary(customColor),
    onPrimary: AppColors.lightOnPrimary,
    secondary: AppColors.lightSecondary,
    onSecondary: AppColors.lightOnSecondary,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface(customColor),
    error: AppColors.lightError,
    onError: AppColors.lightOnError,
  );
  
  static ColorScheme darkColorScheme(Color customColor) => ColorScheme.dark(
    primary: AppColors.darkPrimary(customColor),
    onPrimary: AppColors.darkOnPrimary,
    secondary: AppColors.darkSecondary,
    onSecondary: AppColors.darkOnSecondary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,  // Always white for readability
    error: AppColors.darkError,
    onError: AppColors.darkOnError,
  );
  
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(color: textColor),
      displayMedium: TextStyle(color: textColor),
      displaySmall: TextStyle(color: textColor),
      headlineLarge: TextStyle(color: textColor),
      headlineMedium: TextStyle(color: textColor),
      headlineSmall: TextStyle(color: textColor),
      titleLarge: TextStyle(color: textColor),
      titleMedium: TextStyle(color: textColor),
      titleSmall: TextStyle(color: textColor),
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
      bodySmall: TextStyle(color: textColor),
      labelLarge: TextStyle(color: textColor),
      labelMedium: TextStyle(color: textColor),
      labelSmall: TextStyle(color: textColor),
    );
  }
  
  static ThemeData lightTheme(Color customColor) {
    final colorScheme = lightColorScheme(customColor);
    final textColor = colorScheme.onSurface;
    
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      
      // Text theme
      textTheme: _buildTextTheme(textColor),
      
      // Icon themes
      iconTheme: IconThemeData(color: textColor.withOpacity(0.8)),
      primaryIconTheme: IconThemeData(color: textColor),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: textColor.withOpacity(0.1)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.1)),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
        prefixIconColor: textColor,
        suffixIconColor: textColor.withOpacity(0.7),
      ),
      
      // List tiles
      listTileTheme: ListTileThemeData(
        textColor: textColor,
        iconColor: textColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: textColor,
          elevation: 0,
          side: BorderSide(color: textColor.withOpacity(0.1)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: textColor.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(color: textColor),
        iconTheme: IconThemeData(color: textColor),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w500),
        contentTextStyle: TextStyle(color: textColor),
      ),
      
      // Bottom nav & drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: textColor.withOpacity(0.12),
      ),
      
      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        textStyle: TextStyle(color: textColor),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
    );
  }
  
  static ThemeData darkTheme(Color customColor) {
    final colorScheme = darkColorScheme(customColor);
    final textColor = colorScheme.onSurface;  // Off-white
    
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      
      // Text theme
      textTheme: _buildTextTheme(textColor),
      
      // Icon themes
      iconTheme: IconThemeData(color: textColor.withOpacity(0.9)),
      primaryIconTheme: IconThemeData(color: textColor),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: textColor.withOpacity(0.1)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.1)),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
        prefixIconColor: textColor,
        suffixIconColor: textColor.withOpacity(0.7),
      ),
      
      // List tiles
      listTileTheme: ListTileThemeData(
        textColor: textColor,
        iconColor: textColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: textColor,
          elevation: 0,
          side: BorderSide(color: textColor.withOpacity(0.1)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: textColor.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(color: textColor),
        iconTheme: IconThemeData(color: textColor),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w500),
        contentTextStyle: TextStyle(color: textColor),
      ),
      
      // Bottom nav & drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: textColor.withOpacity(0.12),
      ),
      
      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        textStyle: TextStyle(color: textColor),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
    );
  }
}