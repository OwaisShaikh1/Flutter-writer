import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/literature_item.dart';
import '../providers/literature_provider.dart';
import '../pages/introduction_page.dart';
import '../pages/author_profile_page.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class LiteratureList extends StatelessWidget {
  final List<LiteratureItem> items;

  const LiteratureList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
      ),
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
    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    item.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                
                  // Author & Type row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (item.authorId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AuthorProfilePage(
                                  authorId: item.authorId!,
                                  authorName: item.author,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          item.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats row - minimal
                  Consumer<LiteratureProvider>(
                    builder: (context, provider, _) {
                      final currentItem = provider.getItemById(item.id) ?? item;
                      return Row(
                        children: [
                          _buildMiniStat(Icons.star_rounded, currentItem.rating.toStringAsFixed(1)),
                          const SizedBox(width: 16),
                          _buildMiniStat(
                            currentItem.isLikedByUser ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                            '${currentItem.likes}',
                            onTap: () => provider.toggleLike(item.id),
                            color: currentItem.isLikedByUser ? Colors.red : null,
                          ),
                          const SizedBox(width: 16),
                          _buildMiniStat(Icons.menu_book_rounded, '${currentItem.chapters}'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey.withOpacity(0.4)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: (color ?? Colors.grey).withOpacity(0.6),
            ),
          ),
        ],
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
            width: 64,
            height: 84,
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
          width: 64,
          height: 84,
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
      width: 64,
      height: 84,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getTypeIcon(item.type),
        size: 30,
        color: _getTypeColor(item.type, context).withOpacity(0.3),
      ),
    );
  }

  Color _getTypeColor(String type, BuildContext context) {
    switch (type.toLowerCase()) {
      case 'drama':
        return AppColors.drama;
      case 'poetry':
        return AppColors.poetry;
      case 'novel':
        return AppColors.novel;
      case 'article':
        return AppColors.article;
      default:
        return AppColors.other;
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

  Color _getTypeColor(String type, BuildContext context) {
    switch (type.toLowerCase()) {
      case 'drama':
        return AppColors.drama;
      case 'poetry':
        return AppColors.poetry;
      case 'novel':
        return AppColors.novel;
      case 'article':
        return AppColors.article;
      default:
        return AppColors.other;
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
