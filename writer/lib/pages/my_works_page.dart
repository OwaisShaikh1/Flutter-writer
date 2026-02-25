import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/literature_provider.dart';
import '../providers/auth_provider.dart';
import '../models/literature_item.dart';
import 'edit_literature_page.dart';
import 'create_literature_page.dart';

class MyWorksPage extends StatefulWidget {
  const MyWorksPage({super.key});

  @override
  State<MyWorksPage> createState() => _MyWorksPageState();
}

class _MyWorksPageState extends State<MyWorksPage> {
  @override
  void initState() {
    super.initState();
    // Refresh my works when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LiteratureProvider>(context, listen: false).refreshMyWorks();
    });
  }

  void _navigateToCreateLiterature() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateLiteraturePage()),
    );
    
    if (result == true && mounted) {
      // Refresh the list after creating new literature
      Provider.of<LiteratureProvider>(context, listen: false).refreshMyWorks();
    }
  }

  void _navigateToEditLiterature(LiteratureItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLiteraturePage(item: item),
      ),
    );
    
    if (result == true && mounted) {
      // Refresh the list after editing
      Provider.of<LiteratureProvider>(context, listen: false).refreshMyWorks();
    }
  }

  void _confirmDelete(LiteratureItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Literature'),
        content: Text('Are you sure you want to delete "${item.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<LiteratureProvider>(context, listen: false)
                  .deleteItem(item.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${item.title}" deleted'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Works'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer2<LiteratureProvider, AuthProvider>(
        builder: (context, literatureProvider, authProvider, _) {
          if (!authProvider.isAuthenticated) {
            return _buildNotLoggedIn();
          }

          final myWorks = literatureProvider.myWorks;

          if (myWorks.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => literatureProvider.refreshMyWorks(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myWorks.length,
              itemBuilder: (context, index) {
                final item = myWorks[index];
                return _buildWorkCard(item);
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _navigateToCreateLiterature,
            icon: const Icon(Icons.add),
            label: const Text('New Work'),
          );
        },
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Login Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please login to view and manage your works',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.create_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Works Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start writing your first piece of literature!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateLiterature,
              icon: const Icon(Icons.add),
              label: const Text('Create New Work'),
            ),
            const SizedBox(height: 16),
            // Button to claim orphan items (items created before account system)
            TextButton.icon(
              onPressed: () async {
                final provider = Provider.of<LiteratureProvider>(context, listen: false);
                final claimed = await provider.claimOrphanItems();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(claimed > 0 
                        ? 'Claimed $claimed existing items!' 
                        : 'No orphan items to claim'),
                      backgroundColor: claimed > 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Claim Existing Items'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkCard(LiteratureItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToEditLiterature(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon based on type
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(item.type),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.type,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sync status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isSynced
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isSynced ? Icons.cloud_done : Icons.cloud_off,
                          size: 14,
                          color: item.isSynced ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isSynced ? 'Synced' : 'Local',
                          style: TextStyle(
                            fontSize: 12,
                            color: item.isSynced ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStat(Icons.book, '${item.chapters} chapters'),
                  const SizedBox(width: 16),
                  _buildStat(Icons.star, item.rating.toStringAsFixed(1)),
                  const Spacer(),
                  // Action buttons
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _navigateToEditLiterature(item),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    onPressed: () => _confirmDelete(item),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Novel':
        return Icons.book;
      case 'Poetry':
        return Icons.format_quote;
      case 'Drama':
        return Icons.theater_comedy;
      case 'Short Story':
        return Icons.short_text;
      case 'Essay':
        return Icons.article;
      case 'Biography':
        return Icons.person_outline;
      default:
        return Icons.book;
    }
  }
}
