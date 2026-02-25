import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../database/dao/chapters_dao.dart';
import '../providers/sync_provider.dart';
import '../models/chapter.dart';
import '../models/literature_item.dart';

class ChapterReaderPage extends StatefulWidget {
  final LiteratureItem item;
  final int initialChapter;

  const ChapterReaderPage({
    super.key,
    required this.item,
    this.initialChapter = 1,
  });

  @override
  State<ChapterReaderPage> createState() => _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<ChapterReaderPage> {
  late ChaptersDao _chaptersDao;
  int _currentChapter = 1;
  Chapter? _chapter;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.initialChapter;
    _chaptersDao = ChaptersDao(Provider.of<AppDatabase>(context, listen: false));
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entity = await _chaptersDao.getChapter(widget.item.id, _currentChapter);
      
      if (entity != null) {
        setState(() {
          _chapter = Chapter.fromEntity(entity);
          _isLoading = false;
        });
      } else {
        // Try to download from server
        final syncProvider = Provider.of<SyncProvider>(context, listen: false);
        final success = await syncProvider.downloadChapter(widget.item.id, _currentChapter);
        
        if (success) {
          final downloaded = await _chaptersDao.getChapter(widget.item.id, _currentChapter);
          if (downloaded != null) {
            setState(() {
              _chapter = Chapter.fromEntity(downloaded);
              _isLoading = false;
            });
          } else {
            setState(() {
              _error = 'Failed to load chapter';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _error = 'Chapter not available offline. Connect to internet to download.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading chapter: $e';
        _isLoading = false;
      });
    }
  }

  void _goToChapter(int chapter) {
    if (chapter >= 1 && chapter <= widget.item.chapters) {
      setState(() {
        _currentChapter = chapter;
      });
      _loadChapter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
        actions: [
          // Chapter selector
          PopupMenuButton<int>(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Go to chapter',
            onSelected: _goToChapter,
            itemBuilder: (context) {
              return List.generate(
                widget.item.chapters,
                (index) => PopupMenuItem(
                  value: index + 1,
                  child: Text('Chapter ${index + 1}'),
                ),
              );
            },
          ),
          // Download all chapters
          Consumer<SyncProvider>(
            builder: (context, syncProvider, _) {
              return IconButton(
                icon: syncProvider.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                tooltip: 'Download all chapters',
                onPressed: syncProvider.isSyncing
                    ? null
                    : () async {
                        final result = await syncProvider.downloadChapters(widget.item.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor: result.success ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                            ),
                          );
                          if (result.success) {
                            _loadChapter();
                          }
                        }
                      },
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 24),
              Consumer<SyncProvider>(
                builder: (context, syncProvider, _) {
                  if (!syncProvider.isOnline) {
                    return Text(
                      'You are currently offline',
                      style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                    );
                  }
                  return ElevatedButton.icon(
                    onPressed: _loadChapter,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Chapter'),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_chapter == null) {
      return const Center(child: Text('No content available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter title
          Text(
            _chapter!.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          // Chapter info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chapter $_currentChapter of ${widget.item.chapters}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),
              if (_chapter!.isDownloaded) ...[
                const SizedBox(width: 8),
                Icon(Icons.offline_pin, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Available offline',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          
          // Chapter content
          SelectableText(
            _chapter!.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous button
            ElevatedButton.icon(
              onPressed: _currentChapter > 1
                  ? () => _goToChapter(_currentChapter - 1)
                  : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
            
            // Chapter indicator
            Text(
              '$_currentChapter / ${widget.item.chapters}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            
            // Next button
            ElevatedButton.icon(
              onPressed: _currentChapter < widget.item.chapters
                  ? () => _goToChapter(_currentChapter + 1)
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
