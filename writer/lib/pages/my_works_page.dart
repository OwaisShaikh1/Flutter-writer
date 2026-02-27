import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/literature_provider.dart';
import '../providers/auth_provider.dart';
import '../models/literature_item.dart';
import '../theme/app_theme.dart';
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'drama': return AppColors.drama;
      case 'poetry': return AppColors.poetry;
      case 'novel': return AppColors.novel;
      case 'article': return AppColors.article;
      default: return AppColors.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'MY MANUSCRIPTS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: myWorks.length,
              separatorBuilder: (context, index) => Divider(
                height: 48,
                thickness: 1,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              ),
              itemBuilder: (context, index) {
                final item = myWorks[index];
                return _buildWorkItem(item);
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) return const SizedBox.shrink();
          return FloatingActionButton(
            elevation: 2,
            onPressed: _navigateToCreateLiterature,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_person_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            const Text(
              'MEMBERS ONLY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please login to access your personal literary archives.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.draw_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
            ),
            const SizedBox(height: 24),
            const Text(
              'THE CANVAS IS BLANK',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Begin your first masterpiece today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: _navigateToCreateLiterature,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('CREATE NEW WORK'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkItem(LiteratureItem item) {
    return InkWell(
      onTap: () => _navigateToEditLiterature(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          item.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          size: 12,
                          color: item.isSynced ? Colors.blue.withOpacity(0.7) : Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isSynced ? 'SYNCED' : 'LOCAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: item.isSynced ? Colors.blue.withOpacity(0.7) : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                onSelected: (value) {
                  if (value == 'edit') _navigateToEditLiterature(item);
                  if (value == 'delete') _confirmDelete(item);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _minimalStat('${item.chapters} CHAPTERS'),
              const SizedBox(width: 24),
              _minimalStat('${item.rating.toStringAsFixed(1)} RATING'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _minimalStat(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
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
