import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/literature_item.dart';
import '../models/comment.dart';
import '../providers/literature_provider.dart';
import '../providers/sync_provider.dart';
import '../services/api_service.dart';
import 'chapter_reader_page.dart';

class IntroductionPage extends StatefulWidget {
  final Map<String, dynamic> literatureItem;

  const IntroductionPage({super.key, required this.literatureItem});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  
  bool _isLiked = false;
  int _likesCount = 0;
  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  bool _isTogglingLike = false;
  bool _showComments = false;

  Map<String, dynamic> get literatureItem => widget.literatureItem;

  @override
  void initState() {
    super.initState();
    _isLiked = literatureItem['isLikedByUser'] ?? false;
    _likesCount = literatureItem['likes'] ?? 0;
    _loadLikeStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeStatus() async {
    final itemId = literatureItem['id'] ?? 0;
    if (itemId > 0) {
      try {
        final liked = await _apiService.checkLikeStatus(itemId);
        if (mounted) {
          setState(() => _isLiked = liked);
        }
      } catch (_) {}
    }
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;
    
    final itemId = literatureItem['id'] ?? 0;
    if (itemId <= 0) return;

    setState(() => _isTogglingLike = true);
    
    try {
      final result = await _apiService.toggleLike(itemId);
      if (result != null && mounted) {
        setState(() {
          _isLiked = result['liked'] ?? false;
          _likesCount = result['likes_count'] ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingLike = false);
    }
  }

  Future<void> _loadComments() async {
    final itemId = literatureItem['id'] ?? 0;
    if (itemId <= 0) return;

    setState(() => _isLoadingComments = true);
    
    try {
      final comments = await _apiService.fetchComments(itemId);
      if (mounted) {
        setState(() => _comments = comments);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final itemId = literatureItem['id'] ?? 0;
    if (itemId <= 0) return;

    try {
      final comment = await _apiService.addComment(itemId, content);
      if (comment != null && mounted) {
        setState(() {
          _comments.insert(0, comment);
          _commentController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      final success = await _apiService.deleteComment(commentId);
      if (success && mounted) {
        setState(() {
          _comments.removeWhere((c) => c.remoteId == commentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Literature Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                image: literatureItem['image'] != null
                    ? DecorationImage(
                        image: NetworkImage(literatureItem['image']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: literatureItem['image'] == null
                  ? Center(
                      child: Icon(
                        Icons.book,
                        size: 100,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    )
                  : null,
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    literatureItem['title'] ?? 'Untitled',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Row(
                    children: [
                      Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text(
                        literatureItem['author'] ?? 'Unknown Author',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      literatureItem['type'] ?? 'Literature',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rating Section
                  Row(
                    children: [
                      Icon(Icons.star, color: Theme.of(context).colorScheme.tertiary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${literatureItem['rating'] ?? 0.0}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        ' / 5.0',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Row (Chapters, Comments & Likes)
                  Row(
                    children: [
                      // Chapters
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary, size: 28),
                              const SizedBox(height: 6),
                              Text(
                                '${literatureItem['chapters'] ?? 0}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Chapters',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Comments - tappable to show comments section
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _showComments = !_showComments);
                            if (_showComments && _comments.isEmpty) {
                              _loadComments();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _showComments ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.comment, color: Theme.of(context).colorScheme.secondary, size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  '${literatureItem['comments'] ?? 0}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Comments',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Likes - tappable to toggle like
                      Expanded(
                        child: GestureDetector(
                          onTap: _isTogglingLike ? null : _toggleLike,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isLiked ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _isTogglingLike
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(
                                        _isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: Theme.of(context).colorScheme.error,
                                        size: 28,
                                      ),
                                const SizedBox(height: 6),
                                Text(
                                  '$_likesCount',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Likes',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description Section
                  if (literatureItem['description'] != null) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      literatureItem['description'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Comments Section
                  if (_showComments) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comments',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _showComments = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Add comment input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addComment,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Icon(Icons.send),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Comments list
                    if (_isLoadingComments)
                      const Center(child: CircularProgressIndicator())
                    else if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No comments yet. Be the first to comment!',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            child: Text(
                                              comment.username.isNotEmpty
                                                  ? comment.username[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment.username,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(comment.createdAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (comment.remoteId != null)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20),
                                          onPressed: () => _deleteComment(comment.remoteId!),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(comment.content),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Convert map to LiteratureItem and navigate to reader
                            final item = LiteratureItem(
                              id: literatureItem['id'] ?? 0,
                              title: literatureItem['title'] ?? '',
                              author: literatureItem['author'] ?? '',
                              type: literatureItem['type'] ?? '',
                              rating: (literatureItem['rating'] ?? 0.0).toDouble(),
                              chapters: literatureItem['chapters'] ?? 1,
                              comments: literatureItem['comments'] ?? 0,
                              imageUrl: literatureItem['image'],
                              description: literatureItem['description'] ?? '',
                            );
                            
                            if (item.chapters > 0) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChapterReaderPage(item: item),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No chapters available')),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Reading'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Consumer<LiteratureProvider>(
                        builder: (context, provider, _) {
                          final itemId = literatureItem['id'] ?? 0;
                          final item = provider.getItemById(itemId);
                          final isFavorite = item?.isFavorite ?? false;
                          
                          return ElevatedButton(
                            onPressed: () {
                              if (itemId > 0) {
                                provider.toggleFavorite(itemId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isFavorite
                                          ? 'Removed from Library'
                                          : 'Added to Library',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Icon(
                              isFavorite ? Icons.bookmark : Icons.bookmark_add,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  // Download for offline button
                  const SizedBox(height: 16),
                  Consumer<SyncProvider>(
                    builder: (context, syncProvider, _) {
                      return OutlinedButton.icon(
                        onPressed: syncProvider.isSyncing
                            ? null
                            : () async {
                                final itemId = literatureItem['id'] ?? 0;
                                if (itemId > 0) {
                                  final result = await syncProvider.downloadChapters(itemId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result.message),
                                        backgroundColor: result.success ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: syncProvider.isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_for_offline),
                        label: Text(
                          syncProvider.isSyncing
                              ? 'Downloading...'
                              : 'Download for Offline',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 0),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
