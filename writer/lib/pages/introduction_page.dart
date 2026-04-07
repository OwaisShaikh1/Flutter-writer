import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/literature_item.dart';
import '../models/comment.dart';
import '../providers/literature_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/platform_image/platform_local_image.dart';
import 'chapter_reader_page.dart';
import 'author_profile_page.dart';

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
  bool _isInLibrary = false;
  int _likesCount = 0;
  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  bool _isTogglingLike = false;
  bool _isTogglingLibrary = false;
  bool _showComments = false;

  Map<String, dynamic> get literatureItem => widget.literatureItem;

  @override
  void initState() {
    super.initState();
    _isLiked = literatureItem['isLikedByUser'] ?? false;
    _likesCount = literatureItem['likes'] ?? 0;
    _loadLikeStatus();
    _loadLibraryStatus();
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

  Future<void> _loadLibraryStatus() async {
    final itemId = literatureItem['id'] ?? 0;
    if (itemId > 0) {
      try {
        final inLibrary = await _apiService.checkLibraryStatus(itemId);
        if (mounted) {
          setState(() => _isInLibrary = inLibrary);
        }
      } catch (_) {}
    }
  }

  Future<void> _toggleLibrary() async {
    if (_isTogglingLibrary) return;
    
    final itemId = literatureItem['id'] ?? 0;
    if (itemId <= 0) return;

    setState(() => _isTogglingLibrary = true);
    
    try {
      bool success;
      if (_isInLibrary) {
        success = await _apiService.removeFromLibrary(itemId);
      } else {
        success = await _apiService.addToLibrary(itemId);
      }
      
      if (success && mounted) {
        setState(() => _isInLibrary = !_isInLibrary);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isInLibrary ? 'Added to Library' : 'Removed from Library'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update library: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingLibrary = false);
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

  Widget _buildDetailImage() {
    final itemId = literatureItem['id'];
    final provider = Provider.of<LiteratureProvider>(context, listen: false);
    final item = itemId is int ? provider.getItemById(itemId) : null;

    final localWidget = buildLocalImageWidget(
      item?.imageLocalPath,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
    );
    if (localWidget != null) {
      return localWidget;
    }

    final rawImage = (literatureItem['image'] ?? '').toString();
    if (rawImage.isNotEmpty) {
      final isDirect = rawImage.startsWith('http') ||
          rawImage.startsWith('blob:') ||
          rawImage.startsWith('file:') ||
          rawImage.startsWith('data:');
      final imageUrl = isDirect ? rawImage : '${ApiConstants.baseUrl}/$rawImage';

      if (rawImage.startsWith('blob:') || rawImage.startsWith('file:') || rawImage.startsWith('data:')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 300,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        );
      }

      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
        placeholder: (_, __) => _buildImagePlaceholder(),
        errorWidget: (_, __, ___) => _buildImagePlaceholder(),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.book,
        size: 100,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
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

  Widget _buildFlatStatItem(BuildContext context, IconData icon, Color color, String value, String label, {VoidCallback? onTap, bool isLoading = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    )
                  : Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    // Refresh all data for the page
    final itemId = literatureItem['id'] ?? 0;
    
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing data...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Also sync with backend and refresh the literature provider data
      final literatureProvider = Provider.of<LiteratureProvider>(context, listen: false);
      await literatureProvider.syncWithBackend();
      await literatureProvider.refreshMyWorks();
      
      // Refresh main item data if we have a valid ID
      if (itemId > 0) {
        final freshItem = await _apiService.fetchItem(itemId);
        if (freshItem != null && mounted) {
          // Keep legacy map keys expected by this page.
          setState(() {
            widget.literatureItem.clear();
            widget.literatureItem.addAll({
              'id': freshItem.id,
              'title': freshItem.title,
              'author': freshItem.author,
              'authorId': freshItem.authorId,
              'type': freshItem.type,
              'rating': freshItem.rating,
              'chapters': freshItem.chapters,
              'comments': freshItem.comments,
              'likes': freshItem.likes,
              'isLikedByUser': freshItem.isLikedByUser,
              'image': freshItem.imageUrl,
              'description': freshItem.description,
            });
            _likesCount = freshItem.likes;
          });
        }
      }
      
      // Refresh interaction statuses and comments
      await Future.wait([
        _loadLikeStatus(),
        _loadLibraryStatus(),
        if (_showComments) _loadComments(),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content refreshed successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(literatureItem['type'] ?? '');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Literature Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Image Section
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildDetailImage(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    literatureItem['title'] ?? 'Untitled',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 6),

                  // Author & Type Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Author
                      InkWell(
                        onTap: () {
                          final authorId = literatureItem['authorId'];
                          if (authorId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AuthorProfilePage(
                                  authorId: authorId,
                                  authorName: literatureItem['author'] ?? 'Unknown Author',
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(Icons.person, size: 12, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                literatureItem['author'] ?? 'Unknown Author',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Minimal Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          literatureItem['type']?.toUpperCase() ?? 'LITERATURE',
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats Row (Rating, Chapters, Comments & Likes)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Rating
                      _buildFlatStatItem(
                        context,
                        Icons.star_rounded,
                        Colors.amber,
                        '${literatureItem['rating'] ?? 0.0}',
                        'Rating',
                      ),
                      
                      // Chapters
                      _buildFlatStatItem(
                        context,
                        Icons.menu_book_rounded,
                        Colors.teal,
                        '${literatureItem['chapters'] ?? 0}',
                        'Chapters',
                      ),

                      // Comments
                      _buildFlatStatItem(
                        context,
                        _showComments ? Icons.comment_rounded : Icons.comment_outlined,
                        Colors.blue,
                        '${literatureItem['comments'] ?? 0}',
                        'Comments',
                        onTap: () {
                          setState(() => _showComments = !_showComments);
                          if (_showComments && _comments.isEmpty) {
                            _loadComments();
                          }
                        },
                      ),

                      // Likes
                      _buildFlatStatItem(
                        context,
                        _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        Colors.red,
                        '$_likesCount',
                        'Likes',
                        onTap: _isTogglingLike ? null : _toggleLike,
                        isLoading: _isTogglingLike,
                      ),

                      // Library
                      _buildFlatStatItem(
                        context,
                        _isInLibrary ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        Colors.deepPurple,
                        _isInLibrary ? 'IN LIB' : 'ADD',
                        'Library',
                        onTap: _isTogglingLibrary ? null : _toggleLibrary,
                        isLoading: _isTogglingLibrary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description Section
                  if (literatureItem['description'] != null) ...[
                    Text(
                      'About this work',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      literatureItem['description'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                          'COMMENTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() => _showComments = false),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Add comment input (Naked style)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Add a thought...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _addComment,
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'POST',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
                  
                  // Access settings for offline download
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to settings or show info
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Use Settings to download content for offline reading'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Go to Settings for Downloads'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
