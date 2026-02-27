import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const ProfileHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        children: [
          // Central Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: userProfile['profileImage'] == null
                ? Icon(
                    Icons.person_outline_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  )
                : ClipOval(
                    child: Image.network(
                      userProfile['profileImage'],
                      fit: BoxFit.cover,
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Name and Info
          Text(
            userProfile['name'] ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            userProfile['username'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          if (userProfile['bio'] != null)
            Text(
              userProfile['bio'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
