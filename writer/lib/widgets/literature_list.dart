import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/literature_item.dart';
import '../providers/literature_provider.dart';
import '../pages/introduction_page.dart';
import '../pages/author_profile_page.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'platform_image/platform_local_image.dart';

class LiteratureList extends StatelessWidget {
  final List<LiteratureItem> items;

  const LiteratureList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isCardLayout = Provider.of<ThemeProvider>(context).isCardLayout;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isCardLayout
          ? LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                // Simple responsive grid for web/desktop.
                final crossAxisCount = width >= 1000
                    ? 4
                    : width >= 700
                        ? 3
                        : 2;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: items.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _LiteratureCard(item: item);
                  },
                );
              },
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: items.length,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return _LiteratureListTile(item: item);
              },
            ),
    );
  }
}

class _LiteratureListTile extends StatelessWidget {
  final LiteratureItem item;

  const _LiteratureListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 50,
          height: 70,
          child: _LiteratureCard(item: item)._buildImage(context, width: 50, height: 70),
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.author,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                item.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Icon(
                item.isLikedByUser ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 14,
                color: item.isLikedByUser ? Colors.red : Colors.grey.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                '${item.likes}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IntroductionPage(
              literatureItem: item.toMap(),
            ),
          ),
        );
        if (context.mounted) {
          Provider.of<LiteratureProvider>(context, listen: false)
              .refreshItemData(item.id);
        }
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
        if (context.mounted) {
          Provider.of<LiteratureProvider>(context, listen: false)
              .refreshItemData(item.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 3/4,
                  child: _buildImage(context, width: double.infinity, height: null),
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.author,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(Icons.star_rounded, item.rating.toStringAsFixed(1), color: Colors.amber),
                          _buildMiniStat(
                            item.isLikedByUser ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            '${item.likes}',
                            color: item.isLikedByUser ? Colors.red : Colors.grey.withOpacity(0.4),
                          ),
                          _buildMiniStat(Icons.menu_book_rounded, '${item.chapters}', color: Colors.teal),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

  Widget _buildImage(BuildContext context, {double? width, double? height}) {
    // Check for local image first
    final localImage = buildLocalImageWidget(
      item.imageLocalPath,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
    if (localImage != null) {
      return localImage;
    }
    // Check for network image
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      final imageUrl = item.imageUrl!.startsWith('http')
          ? item.imageUrl!
          : '${ApiConstants.baseUrl}/${item.imageUrl}';
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => _buildPlaceholder(ctx),
        errorWidget: (ctx, url, error) => _buildPlaceholder(ctx),
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
      case 'short story':
        return AppColors.drama;
      case 'essay':
        return AppColors.article;
      case 'biography':
        return AppColors.other;
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
      case 'short story':
        return Icons.short_text;
      case 'essay':
        return Icons.article;
      case 'biography':
        return Icons.person_outline;
      default:
        return Icons.book;
    }
  }
}
