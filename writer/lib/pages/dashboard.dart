import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/literature_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/header.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_section.dart';
import '../widgets/literature_list.dart';
import '../widgets/offline_indicator.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'create_literature_page.dart';
import 'my_works_page.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
    // Load literature data when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final literatureProvider = Provider.of<LiteratureProvider>(context, listen: false);
      // Sync all items instead of just user's works
      literatureProvider.syncWithBackend();
    });
  }

  Future<void> _handleRefresh() async {
    final literatureProvider = Provider.of<LiteratureProvider>(context, listen: false);
    
    // Sync all literature data from backend
    await literatureProvider.syncWithBackend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Offline indicator at the top
            const OfflineIndicator(),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         kToolbarHeight - 100, // Account for offline indicator and padding
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with profile and logout
                        _buildHeader(),
                        const SizedBox(height: 12),
                        
                        // Search bar
                        Consumer<LiteratureProvider>(
                          builder: (context, provider, _) {
                            return LiteratureSearchBar(
                              onChanged: (value) => provider.setSearchQuery(value),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Filter section
                        Consumer<LiteratureProvider>(
                          builder: (context, provider, _) {
                            return FilterSection(
                              selected: provider.selectedFilter,
                              onSelect: (filter) => provider.setFilter(filter),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Literature list
                        Expanded(
                          child: Consumer<LiteratureProvider>(
                            builder: (context, provider, _) {
                              if (provider.isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              
                              if (provider.items.isEmpty) {
                                return _buildEmptyState(provider);
                              }
                              
                              return LiteratureList(items: provider.items);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateLiterature,
        tooltip: 'Write new work',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(child: Header()),
        Row(
          children: [
            // My Works button
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isAuthenticated) {
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit_document),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyWorksPage()),
                      );
                    },
                    tooltip: 'My Works',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Profile button
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              tooltip: 'Profile',
            ),
            // Logout button
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isAuthenticated) {
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      // Reset provider states for user change
                      await context.read<LiteratureProvider>().resetForUserChange();
                      await context.read<SyncProvider>().resetForUserChange();
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      }
                    },
                    tooltip: 'Logout',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(LiteratureProvider provider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 400, // Minimum height to allow pull-to-refresh
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                provider.searchQuery.isNotEmpty || provider.selectedFilter != 'All'
                    ? 'No items found'
                    : 'Your library is empty',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.searchQuery.isNotEmpty || provider.selectedFilter != 'All'
                    ? 'Try adjusting your search criteria or pull down to refresh'
                    : 'Create your first work, pull down to refresh, or check Settings to sync with server',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 32),
              if (provider.searchQuery.isNotEmpty || provider.selectedFilter != 'All')
                TextButton(
                  onPressed: () => provider.clearFilters(),
                  child: const Text('Clear all filters'),
                )
              else
                TextButton.icon(
                  onPressed: _navigateToCreateLiterature,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create your first work'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateLiterature() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateLiteraturePage()),
    );
    
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New literature created!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

