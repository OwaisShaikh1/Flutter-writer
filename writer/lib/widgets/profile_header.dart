import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const ProfileHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.06),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar on the left
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.outline,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: userProfile['profileImage'] == null
                ? Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  )
                : ClipOval(
                    child: Image.network(
                      userProfile['profileImage'],
                      fit: BoxFit.cover,
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // Name, role/email and bio to the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        userProfile['name'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (userProfile['role'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text(userProfile['role'], style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(userProfile['username'] ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),

                const SizedBox(height: 6),

                if (userProfile['email'] != null)
                  Text(userProfile['email'], style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                  )),

                if (userProfile['bio'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    userProfile['bio'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
