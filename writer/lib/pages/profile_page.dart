import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/literature_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_about.dart';
import 'login_page.dart';
import 'settings_page.dart';
// replaced recent activity with local library section

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Refresh user profile in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().refreshUserProfile();
      }
    });
  }

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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => authProvider.refreshUserProfile(),
                tooltip: 'Refresh',
              ),
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
                    // Reset provider states for user change
                    await context.read<LiteratureProvider>().resetForUserChange();
                    await context.read<SyncProvider>().resetForUserChange();
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
          body: RefreshIndicator(
            onRefresh: () => authProvider.refreshUserProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(userProfile: userProfile),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileStats(userStats: userStats),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader(context, 'About'),
                        const SizedBox(height: 12),
                        ProfileAbout(userProfile: userProfile),
                        
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader(context, 'Library'),
                        const SizedBox(height: 12),
                        ProfileLibrary(userBooks: userBooks),
                        
                        const SizedBox(height: 40),

                        // Action Buttons - Minimal
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon...'), behavior: SnackBarBehavior.floating)),
                                style: TextButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  'EDIT PROFILE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {},
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                padding: const EdgeInsets.all(12),
                              ),
                              icon: Icon(Icons.share_outlined, size: 20, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            thickness: 1,
          ),
        ),
      ],
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