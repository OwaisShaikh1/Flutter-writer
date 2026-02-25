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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with profile and logout
                  _buildHeader(),
                  const SizedBox(height: 20),
                  
                  // Search bar
                  Consumer<LiteratureProvider>(
                    builder: (context, provider, _) {
                      return LiteratureSearchBar(
                        onChanged: (value) => provider.setSearchQuery(value),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Filter section
                  Consumer<LiteratureProvider>(
                    builder: (context, provider, _) {
                      return FilterSection(
                        selected: provider.selectedFilter,
                        onSelect: (filter) => provider.setFilter(filter),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Sync status and button
                  _buildSyncSection(),
                  const SizedBox(height: 16),
                  
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateLiterature,
        icon: const Icon(Icons.add),
        label: const Text('Write'),
        tooltip: 'Create new literature',
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
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
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
          children: [
            // Sync button
            ElevatedButton.icon(
              onPressed: literature.isSyncing || sync.isSyncing
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
              icon: literature.isSyncing || sync.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: Text(
                literature.isSyncing || sync.isSyncing
                    ? 'Syncing...'
                    : 'Sync',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Item count
            Text(
              '${literature.filteredCount} of ${literature.totalItems} items',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            
            const Spacer(),
            
            // Last sync time
            if (literature.lastSyncTime != null)
              Text(
                'Last sync: ${_formatTime(literature.lastSyncTime!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
            Icons.menu_book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            provider.searchQuery.isNotEmpty || provider.selectedFilter != 'All'
                ? 'No items match your search'
                : 'No literature items yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.searchQuery.isNotEmpty || provider.selectedFilter != 'All'
                ? 'Try adjusting your filters'
                : 'Tap sync to fetch items from the server',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 24),
          if (provider.searchQuery.isNotEmpty || provider.selectedFilter != 'All')
            TextButton.icon(
              onPressed: () => provider.clearFilters(),
              icon: const Icon(Icons.clear),
              label: const Text('Clear filters'),
            )
          else
            ElevatedButton.icon(
              onPressed: provider.isSyncing
                  ? null
                  : () => provider.syncWithBackend(),
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
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

