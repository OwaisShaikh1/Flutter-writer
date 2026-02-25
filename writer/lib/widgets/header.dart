import 'package:flutter/material.dart';
import '../pages/profile_page.dart';
import '../pages/settings_page.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Dashboard",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
        IconButton(
          icon: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
      ],
    );
  }
}
