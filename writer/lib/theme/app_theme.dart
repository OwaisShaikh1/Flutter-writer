import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors (black gets replaced with custom color)
  static Color lightPrimary(Color customColor) => customColor;      // Custom color replaces black
  static const Color lightOnPrimary = Color(0xFFFFFFFF);            // Pure white
  static const Color lightSecondary = Color(0xFF333333);            // Dark grey
  static const Color lightOnSecondary = Color(0xFFFFFFFF);          // Pure white
  static const Color lightSurface = Color(0xFFFFFFFF);              // Pure white
  static Color lightOnSurface(Color customColor) => customColor;    // Custom color replaces black
  static const Color lightError = Color(0xFF666666);                // Medium grey
  static const Color lightOnError = Color(0xFFFFFFFF);              // Pure white
  
  // Dark Mode Colors - onSurface should be light (white or custom light color)
  static Color darkPrimary(Color customColor) => customColor;       // Custom accent color
  static const Color darkOnPrimary = Color(0xFFFFFFFF);             // WHITE for visibility on primary
  static const Color darkSecondary = Color(0xFFCCCCCC);             // Light grey
  static const Color darkOnSecondary = Color(0xFF000000);           // Pure black
  static const Color darkSurface = Color(0xFF121212);               // Dark grey (not pure black for better UX)
  static const Color darkOnSurface = Color(0xFFFFFFFF);             // WHITE - readable text on dark surface
  static const Color darkError = Color(0xFFCF6679);                 // Light red for errors
  static const Color darkOnError = Color(0xFF000000);               // Pure black
  
  // Shared Monochrome Shades
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF333333);
  static const Color mediumGrey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFF999999);
  static const Color veryLightGrey = Color(0xFFCCCCCC);
  static const Color ultraLightGrey = Color(0xFFE0E0E0);
  static const Color almostWhite = Color(0xFFF5F5F5);
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
      iconTheme: IconThemeData(color: textColor),
      primaryIconTheme: IconThemeData(color: textColor),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w500),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: colorScheme.surface,
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
        prefixIconColor: textColor.withOpacity(0.7),
        suffixIconColor: textColor.withOpacity(0.7),
      ),
      
      // List tiles
      listTileTheme: ListTileThemeData(
        textColor: textColor,
        iconColor: textColor,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary.withOpacity(0.5);
          return colorScheme.outline.withOpacity(0.3);
        }),
      ),
      
      // Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          iconColor: textColor,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
    final textColor = colorScheme.onSurface;  // This is WHITE
    
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      
      // Text theme
      textTheme: _buildTextTheme(textColor),
      
      // Icon themes
      iconTheme: IconThemeData(color: textColor),
      primaryIconTheme: IconThemeData(color: textColor),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w500),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
        prefixIconColor: textColor.withOpacity(0.7),
        suffixIconColor: textColor.withOpacity(0.7),
      ),
      
      // List tiles
      listTileTheme: ListTileThemeData(
        textColor: textColor,
        iconColor: textColor,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary.withOpacity(0.5);
          return colorScheme.outline.withOpacity(0.3);
        }),
      ),
      
      // Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          iconColor: textColor,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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