import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/literature_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_about.dart';
import 'login_page.dart';
import 'settings_page.dart';
// replaced recent activity with local library section

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, LiteratureProvider>(
      builder: (context, authProvider, literatureProvider, _) {
        final user = authProvider.currentUser;
        final favoriteItems = literatureProvider.getFavorites();
        
        // Sample user data - use authenticated user data if available
        final Map<String, dynamic> userProfile = user != null
            ? {
                'name': user.name,
                'username': '@${user.username}',
                'bio': user.bio ?? 'No bio yet',
                'profileImage': null,
                'joinDate': user.createdAt?.toString().substring(0, 10) ?? 'Unknown',
                'location': 'Not specified',
                'website': '',
                'email': user.email,
                'role': 'Reader',
                'contact': '',
                'address': '',
              }
            : {
                'name': 'Literary Enthusiast',
                'username': '@bookworm23',
                'bio': 'Passionate reader and writer exploring the depths of classical and contemporary literature.',
                'profileImage': null,
                'joinDate': 'January 2023',
                'location': 'New York, NY',
                'website': 'literaryjourney.blog',
                'email': 'bookworm23@example.com',
                'role': 'Reader',
                'contact': '+1 (555) 123-4567',
                'address': '123 Book Lane, New York, NY',
              };

        final Map<String, int> userStats = user != null
            ? {
                'following': user.following,
                'followers': user.followers,
                'booksRead': literatureProvider.totalItems,
                'favorites': favoriteItems.length,
                'reviews': 0,
                'articlesWritten': user.posts,
              }
            : {
                'following': 142,
                'followers': 298,
                'booksRead': 67,
                'favorites': 23,
                'reviews': 45,
                'articlesWritten': 12,
              };

        // Build library list from favorites
        final List<Map<String, dynamic>> userBooks = favoriteItems.isNotEmpty
            ? favoriteItems.map((item) => {
                'title': item.title,
                'author': item.author,
                'status': 'reading',
                'progress': 0.5,
              }).toList()
            : [
                {
                  'title': 'Pride and Prejudice',
                  'author': 'Jane Austen',
                  'status': 'reading',
                  'progress': 0.45,
                },
                {
                  'title': '1984',
                  'author': 'George Orwell',
                  'status': 'completed',
                  'progress': 1.0,
                },
              ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ),
              ),
              if (authProvider.isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    }
                  },
                  tooltip: 'Logout',
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            ProfileHeader(userProfile: userProfile),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statistics', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ProfileStats(userStats: userStats),
                  const SizedBox(height: 12),
                  Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ProfileAbout(userProfile: userProfile),
                  const SizedBox(height: 12),
                  Text('Library', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ProfileLibrary(userBooks: userBooks),
                  const SizedBox(height: 12),

                  // Action Buttons (compact)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon...'))),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View Library coming soon...'))),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(8)),
                        child: const Icon(Icons.library_books, size: 18),
                      ),
                    ],
                  ),
                  
                  // Login prompt for unauthenticated users
                  if (!authProvider.isAuthenticated) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text(
                              'Login to sync your reading progress across devices',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginPage()),
                                );
                              },
                              child: const Text('Login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

class ProfileLibrary extends StatelessWidget {
  final List<Map<String, dynamic>> userBooks;
  const ProfileLibrary({super.key, required this.userBooks});

  Color _statusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'reading':
        return Theme.of(context).colorScheme.tertiary;
      case 'completed':
        return Theme.of(context).colorScheme.primary;
      case 'want to read':
      case 'want to read':
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userBooks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final book = userBooks[index];
        final status = (book['status'] ?? '').toString();
        final progress = (book['progress'] is double) ? book['progress'] as double : 0.0;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.book, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book['title'] ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(book['author'] ?? '', style: Theme.of(context).textTheme.bodySmall),
                      if (status.toLowerCase() == 'reading') ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 5,
                          child: LinearProgressIndicator(value: progress, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, color: _statusColor(status, context)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(status, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 11)),
                      backgroundColor: _statusColor(status, context),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}