import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/literature_provider.dart';
import '../providers/auth_provider.dart';
import 'add_chapter_page.dart';

class CreateLiteraturePage extends StatefulWidget {
  const CreateLiteraturePage({super.key});

  @override
  State<CreateLiteraturePage> createState() => _CreateLiteraturePageState();
}

class _CreateLiteraturePageState extends State<CreateLiteraturePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'Novel';
  final List<String> _literatureTypes = [
    'Novel',
    'Poetry',
    'Drama',
    'Short Story',
    'Essay',
    'Biography',
  ];
  
  final List<ChapterDraft> _chapters = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addChapter() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddChapterPage(
          chapterNumber: _chapters.length + 1,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _chapters.add(ChapterDraft(
          number: _chapters.length + 1,
          title: result['title']!,
          content: result['content']!,
        ));
      });
    }
  }

  void _editChapter(int index) async {
    final chapter = _chapters[index];
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddChapterPage(
          chapterNumber: chapter.number,
          initialTitle: chapter.title,
          initialContent: chapter.content,
          isEdit: true,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _chapters[index] = ChapterDraft(
          number: chapter.number,
          title: result['title']!,
          content: result['content']!,
        );
      });
    }
  }

  void _deleteChapter(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chapter'),
        content: Text('Are you sure you want to delete "${_chapters[index].title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _chapters.removeAt(index);
                // Renumber remaining chapters
                for (int i = 0; i < _chapters.length; i++) {
                  _chapters[i] = _chapters[i].copyWith(number: i + 1);
                }
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reorderChapters(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final chapter = _chapters.removeAt(oldIndex);
      _chapters.insert(newIndex, chapter);
      // Renumber chapters
      for (int i = 0; i < _chapters.length; i++) {
        _chapters[i] = _chapters[i].copyWith(number: i + 1);
      }
    });
  }

  Future<void> _saveLiterature() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one chapter'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<LiteratureProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authorName = authProvider.currentUser?.name ?? 'Unknown Author';
      
      await provider.createLiterature(
        title: _titleController.text.trim(),
        author: authorName,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        chapters: _chapters,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Literature created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create literature: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'NEW MANUSCRIPT',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _saveLiterature,
                child: Text(
                  'SAVE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              _buildSectionHeader(context, 'Core details'),
              const SizedBox(height: 24),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Work Title',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Literature Type selector (minimal)
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
                decoration: InputDecoration(
                  hintText: 'Write a brief synopsis...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 48),

              // Chapters Section
              Row(
                children: [
                  Expanded(
                    child: _buildSectionHeader(context, 'Manuscript chapters'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_chapters.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_chapters.isEmpty)
                _buildEmptyChapters()
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _chapters.length,
                  onReorder: _reorderChapters,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    return _buildChapterItem(index, chapter);
                  },
                ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: _chapters.isNotEmpty && !_isLoading
          ? FloatingActionButton(
              onPressed: _addChapter,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _literatureTypes.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = type);
                }
              },
              labelStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyChapters() {
    return InkWell(
      onTap: _addChapter,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
              ),
              const SizedBox(height: 12),
              Text(
                'ADD FIRST CHAPTER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterItem(int index, ChapterDraft chapter) {
    return Column(
      key: ValueKey('${chapter.number}_${chapter.title}'),
      children: [
        InkWell(
          onTap: () => _editChapter(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text(
                  '${chapter.number.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${chapter.content.length} characters',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                  onSelected: (value) {
                    if (value == 'edit') _editChapter(index);
                    if (value == 'delete') _deleteChapter(index);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle_rounded, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
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

// Draft model for chapters before saving
class ChapterDraft {
  final int number;
  final String title;
  final String content;

  ChapterDraft({
    required this.number,
    required this.title,
    required this.content,
  });

  ChapterDraft copyWith({
    int? number,
    String? title,
    String? content,
  }) {
    return ChapterDraft(
      number: number ?? this.number,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}
