import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/literature_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/auth_provider.dart';
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
    // Trigger initial sync when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialSync();
    });
  }

  Future<void> _initialSync() async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    if (syncProvider.isOnline) {
      await syncProvider.syncAll();
    }
  }

  Future<void> _handleRefresh() async {
    final literatureProvider = Provider.of<LiteratureProvider>(context, listen: false);
    await literatureProvider.syncWithBackend();
  }

  void _showSyncMessage(BuildContext context, bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Offline indicator at the top
          const OfflineIndicator(),
          
          Expanded(
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
                  
                  // Sync status and button
                  _buildSyncSection(),
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
                        
                        return RefreshIndicator(
                          onRefresh: _handleRefresh,
                          child: LiteratureList(items: provider.items),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildSyncSection() {
    return Consumer2<LiteratureProvider, SyncProvider>(
      builder: (context, literature, sync, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Item count & Online Status
            Row(
              children: [
                Text(
                  '${literature.totalItems} works',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sync.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  sync.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            
            // Minimal Sync button
            InkWell(
              onTap: literature.isSyncing || sync.isSyncing
                  ? null
                  : () async {
                      final result = await literature.syncWithBackend();
                      if (context.mounted) {
                        _showSyncMessage(
                          context,
                          result.success,
                          result.message,
                        );
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    if (literature.isSyncing || sync.isSyncing)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.sync, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      literature.isSyncing || sync.isSyncing ? 'Syncing' : 'Sync',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(LiteratureProvider provider) {
    return Center(
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
                ? 'Try adjusting your search criteria'
                : 'Sync to fetch your works from the server',
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
              onPressed: provider.isSyncing
                  ? null
                  : () => provider.syncWithBackend(),
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Sync now'),
            ),
        ],
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

