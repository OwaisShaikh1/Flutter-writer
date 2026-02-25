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
      appBar: AppBar(
        title: const Text('Create New Literature'),
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
            TextButton.icon(
              onPressed: _saveLiterature,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter the title of your work',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Literature Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type of Literature',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _literatureTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getTypeIcon(type), size: 20),
                        const SizedBox(width: 8),
                        Text(type),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter a brief description or synopsis',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Chapters Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chapters (${_chapters.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: _addChapter,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Chapter'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_chapters.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.book_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No chapters yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Add Chapter" to start writing',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _chapters.length,
                  onReorder: _reorderChapters,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    return Card(
                      key: ValueKey(chapter),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${chapter.number}'),
                        ),
                        title: Text(chapter.title),
                        subtitle: Text(
                          chapter.content.length > 50
                              ? '${chapter.content.substring(0, 50)}...'
                              : chapter.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editChapter(index),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                              onPressed: () => _deleteChapter(index),
                              tooltip: 'Delete',
                            ),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: _chapters.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addChapter,
              icon: const Icon(Icons.add),
              label: const Text('Add Chapter'),
            )
          : null,
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
