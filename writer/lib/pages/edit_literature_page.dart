import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/literature_provider.dart';
import '../models/literature_item.dart';
import '../models/chapter.dart';
import 'create_literature_page.dart';
import 'add_chapter_page.dart';

class EditLiteraturePage extends StatefulWidget {
  final LiteratureItem item;

  const EditLiteraturePage({super.key, required this.item});

  @override
  State<EditLiteraturePage> createState() => _EditLiteraturePageState();
}

class _EditLiteraturePageState extends State<EditLiteraturePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  late String _selectedType;
  final List<String> _literatureTypes = [
    'Novel',
    'Poetry',
    'Drama',
    'Short Story',
    'Essay',
    'Biography',
  ];
  
  List<ChapterDraft> _chapters = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description);
    _selectedType = widget.item.type;
    
    // Add listeners to detect changes
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    
    // Load existing chapters
    _loadChapters();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _loadChapters() async {
    try {
      final provider = Provider.of<LiteratureProvider>(context, listen: false);
      final chapters = await provider.getChaptersForItem(widget.item.id);
      
      setState(() {
        _chapters = chapters.map((ch) => ChapterDraft(
          number: ch.number,
          title: ch.title,
          content: ch.content,
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chapters: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
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
        _hasChanges = true;
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
        _hasChanges = true;
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
                _hasChanges = true;
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
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one chapter'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<LiteratureProvider>(context, listen: false);
      
      await provider.updateLiterature(
        id: widget.item.id,
        title: _titleController.text.trim(),
        author: widget.item.author,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        chapters: _chapters,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Changes saved successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Literature'),
          actions: [
            if (_isSaving)
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
                onPressed: _hasChanges ? _saveChanges : null,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
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
                            setState(() {
                              _selectedType = value;
                              _hasChanges = true;
                            });
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
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surfaceContainerLowest,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.book_outlined, 
                                  size: 48, 
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No chapters yet',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                              key: ValueKey('${chapter.number}_${chapter.title}'),
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
                                      icon: Icon(
                                        Icons.delete, 
                                        color: Theme.of(context).colorScheme.error
                                      ),
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
        floatingActionButton: _chapters.isNotEmpty && !_isLoading
            ? FloatingActionButton.extended(
                onPressed: _addChapter,
                icon: const Icon(Icons.add),
                label: const Text('Add Chapter'),
              )
            : null,
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
