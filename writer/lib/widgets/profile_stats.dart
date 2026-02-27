import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final Map<String, int> userStats;

  const ProfileStats({super.key, required this.userStats});

  Widget _compactStat(BuildContext context, IconData icon, Color color, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _minimalStat(context, '${userStats['following']}', 'Following'),
          _minimalStat(context, '${userStats['followers']}', 'Followers'),
          _minimalStat(context, '${userStats['articlesWritten']}', 'Works'),
          _minimalStat(context, '${userStats['favorites']}', 'Library'),
        ],
      ),
    );
  }

  Widget _minimalStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
