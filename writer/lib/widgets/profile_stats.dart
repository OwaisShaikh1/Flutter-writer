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
    // Render four compact cards in a single row; on very narrow screens allow horizontal scroll
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 420;

      Widget card(IconData icon, Color color, String value, String label) {
        // Fixed height for uniform cards; content centered vertically
        return SizedBox(
          height: 112,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(height: 6),
                    Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    )),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final children = [
        card(Icons.people, Theme.of(context).colorScheme.primary, '${userStats['following']}', 'Following'),
        card(Icons.favorite, Theme.of(context).colorScheme.secondary, '${userStats['followers']}', 'Followers'),
        card(Icons.menu_book, Theme.of(context).colorScheme.tertiary, '${userStats['booksRead']}', 'Books Read'),
        card(Icons.bookmark, Theme.of(context).colorScheme.outline, '${userStats['favorites']}', 'Favorites'),
      ];

      // Always present stats in a single row. Each card expands to share available space.
      return Row(
        children: children
            .map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8.0), child: w)))
            .toList(),
      );
    });
  }
}
