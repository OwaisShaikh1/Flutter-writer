import 'package:flutter/material.dart';

class ProfileAbout extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const ProfileAbout({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    // Compact, row-wise layout; falls back to wrap on small screens
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        child: LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 420;
          final iconColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.calendar_today, color: iconColor), const SizedBox(width: 10), Expanded(child: Text('Joined ${userProfile['joinDate']}', style: Theme.of(context).textTheme.bodySmall))]),
                const SizedBox(height: 8),
                Row(children: [Icon(Icons.location_on, color: iconColor), const SizedBox(width: 10), Expanded(child: Text(userProfile['location'] ?? userProfile['address'] ?? '', style: Theme.of(context).textTheme.bodySmall))]),
                const SizedBox(height: 8),
                Row(children: [Icon(Icons.phone, color: iconColor), const SizedBox(width: 10), Expanded(child: Text(userProfile['contact'] ?? '', style: Theme.of(context).textTheme.bodySmall))]),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: Row(children: [Icon(Icons.calendar_today, color: iconColor), const SizedBox(width: 8), Text('Joined ${userProfile['joinDate']}', style: Theme.of(context).textTheme.bodyMedium)])),
              Expanded(child: Row(children: [Icon(Icons.location_on, color: iconColor), const SizedBox(width: 8), Text(userProfile['location'] ?? userProfile['address'] ?? '', style: Theme.of(context).textTheme.bodyMedium)])),
              Expanded(child: Row(children: [Icon(Icons.phone, color: iconColor), const SizedBox(width: 8), Text(userProfile['contact'] ?? '', style: Theme.of(context).textTheme.bodyMedium)])),
            ],
          );
        }),
      ),
    );
  }
}
