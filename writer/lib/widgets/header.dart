import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../pages/profile_page.dart';
import '../pages/settings_page.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Dashboard",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () {
                themeProvider.toggleTheme();
              },
            );
          },
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
        
      ],
    );
  }
}
