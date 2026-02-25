import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _customColor = const Color(0xFF000000); // Default black
  
  ThemeMode get themeMode => _themeMode;
  Color get customColor => _customColor;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }
  
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // Load custom color
    final colorValue = prefs.getInt('customColor') ?? 0xFF000000;
    _customColor = Color(colorValue);
    
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', themeMode == ThemeMode.dark);
  }
  
  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customColor', color.value);
  }
  
  Future<void> toggleTheme() async {
    final newThemeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newThemeMode);
  }
  
  Future<void> resetToDefaults() async {
    await setCustomColor(const Color(0xFF000000));
  }
}