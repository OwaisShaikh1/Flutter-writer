import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database.dart';
import '../database/dao/chapters_dao.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';
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
    print('📖 READER: _loadChapter called for chapter $_currentChapter of item ${widget.item.id}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📖 READER: Getting chapter from local DB...');
      final entity = await _chaptersDao.getChapter(widget.item.id, _currentChapter);
      print('📖 READER: Local entity: ${entity != null ? "found" : "null"}');
      
      if (entity != null && entity.isDownloaded) {
        print('📖 READER: Chapter is downloaded, using local');
        // Chapter exists and is up-to-date
        setState(() {
          _chapter = Chapter.fromEntity(entity);
          _isLoading = false;
        });
      } else {
        print('📖 READER: Chapter needs download from server');
        // Chapter doesn't exist or needs update - download from server
        final needsUpdate = entity != null && !entity.isDownloaded;
        
        if (needsUpdate && mounted) {
          // Show brief message that we're updating to latest version
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Updating to latest version...'),
              duration: Duration(milliseconds: 800),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        
        // Pull chapters from API
        print('📖 READER: Creating SyncService...');
        final db = Provider.of<AppDatabase>(context, listen: false);
        final syncService = SyncService(db);
        print('📖 READER: Downloading chapter $_currentChapter only...');
        final downloadedOk = await syncService.downloadChapter(widget.item.id, _currentChapter);
        print('📖 READER: downloadChapter result: $downloadedOk');
        
        if (downloadedOk) {
          final downloaded = await _chaptersDao.getChapter(widget.item.id, _currentChapter);
          if (downloaded != null) {
            setState(() {
              _chapter = Chapter.fromEntity(downloaded);
              _isLoading = false;
            });
            
            if (needsUpdate && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Updated to latest version'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
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
    } catch (e, stack) {
      print('📖 READER: ERROR loading chapter: $e');
      print('📖 READER: Stack trace: $stack');
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          widget.item.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        ),
        centerTitle: true,
        actions: [
          // Chapter selector
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, size: 20),
            tooltip: 'Chapters',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => _buildChapterPicker(),
              );
            },
          ),
          // Chapter options
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 20),
            tooltip: 'Settings',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Use Settings to sync and download content'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildChapterPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Chapter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.item.chapters,
              itemBuilder: (context, index) {
                final chapterNum = index + 1;
                final isCurrent = chapterNum == _currentChapter;
                return ListTile(
                  title: Text(
                    'Chapter $chapterNum',
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  trailing: isCurrent ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _goToChapter(chapterNum);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 16),
            Text(
              'Fetching content...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Consumer<SyncProvider>(
                builder: (context, syncProvider, _) {
                  if (!syncProvider.isOnline) {
                    return Text(
                      'CONNECT TO DOWNLOAD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                  return TextButton.icon(
                    onPressed: _loadChapter,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('RETRY'),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_chapter == null) {
      return const Center(
        child: Text(
          'No content found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter title
          Text(
            _chapter!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          
          // Chapter info - minimal
          Row(
            children: [
              Text(
                'CHAPTER $_currentChapter OF ${widget.item.chapters}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
              ),
              if (_chapter!.isDownloaded) ...[
                const SizedBox(width: 12),
                Icon(Icons.check_circle_outline, 
                    size: 14, 
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
              ],
            ],
          ),
          const SizedBox(height: 48),
          
          // Chapter content rendered with Markdown
          MarkdownBody(
            data: _chapter!.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                height: 1.8,
                fontSize: 17,
                letterSpacing: 0.2,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
              ),
              h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              blockquote: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100), // Extra space at bottom
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous button
            _buildNavButton(
              onTap: _currentChapter > 1 ? () => _goToChapter(_currentChapter - 1) : null,
              label: 'PREVIOUS',
              icon: Icons.chevron_left_rounded,
              isLeft: true,
            ),
            
            // Progress
            Text(
              '$_currentChapter / ${widget.item.chapters}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            
            // Next button
            _buildNavButton(
              onTap: _currentChapter < widget.item.chapters ? () => _goToChapter(_currentChapter + 1) : null,
              label: 'NEXT',
              icon: Icons.chevron_right_rounded,
              isLeft: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required VoidCallback? onTap,
    required String label,
    required IconData icon,
    required bool isLeft,
  }) {
    final color = onTap == null 
        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
        : Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLeft) Icon(icon, color: color, size: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: color,
              ),
            ),
            if (!isLeft) Icon(icon, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
