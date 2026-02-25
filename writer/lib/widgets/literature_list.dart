import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/literature_item.dart';
import '../providers/literature_provider.dart';
import '../pages/introduction_page.dart';
import '../utils/constants.dart';

class LiteratureList extends StatelessWidget {
  final List<LiteratureItem> items;

  const LiteratureList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _LiteratureCard(item: item);
      },
    );
  }
}

class _LiteratureCard extends StatelessWidget {
  final LiteratureItem item;

  const _LiteratureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IntroductionPage(
                literatureItem: item.toMap(),
              ),
            ),
          );
          // Refresh item data when returning from detail page
          if (context.mounted) {
            Provider.of<LiteratureProvider>(context, listen: false)
                .refreshItemData(item.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image/Icon
                _buildImage(context),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    
                    // Author
                    Text(
                      item.author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Type badge and rating
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(item.type, context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.type,
                            style: TextStyle(
                              color: _getTypeColor(item.type, context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Stats row (likes, comments, chapters)
                    Consumer<LiteratureProvider>(
                      builder: (context, provider, _) {
                        // Get fresh item data from provider
                        final currentItem = provider.getItemById(item.id) ?? item;
                        return Row(
                          children: [
                            // Likes count (tappable)
                            GestureDetector(
                              onTap: () => provider.toggleLike(item.id),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    currentItem.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                                    size: 14,
                                    color: currentItem.isLikedByUser ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${currentItem.likes}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Comments count
                            Icon(
                              Icons.comment_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${currentItem.comments}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Chapters count
                            Icon(
                              Icons.menu_book,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${currentItem.chapters}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    // Check for local image first
    if (item.imageLocalPath != null) {
      final file = File(item.imageLocalPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 80,
            height: 100,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    // Check for network image
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      final imageUrl = item.imageUrl!.startsWith('http')
          ? item.imageUrl!
          : '${ApiConstants.baseUrl}/${item.imageUrl}';
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 80,
          height: 100,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => _buildPlaceholder(ctx),
          errorWidget: (ctx, url, error) => _buildPlaceholder(ctx),
        ),
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: _getTypeColor(item.type, context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getTypeIcon(item.type),
        size: 36,
        color: _getTypeColor(item.type, context),
      ),
    );
  }

  Color _getTypeColor(String type, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type.toLowerCase()) {
      case 'drama':
        return colorScheme.onSurface;
      case 'poetry':
        return colorScheme.onSurface.withOpacity(0.8);
      case 'novel':
        return colorScheme.onSurface.withOpacity(0.6);
      case 'article':
        return colorScheme.onSurface.withOpacity(0.4);
      default:
        return colorScheme.outline;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'drama':
        return Icons.theater_comedy;
      case 'poetry':
        return Icons.format_quote;
      case 'novel':
        return Icons.auto_stories;
      case 'article':
        return Icons.article;
      default:
        return Icons.book;
    }
  }
}
