import 'package:flutter/material.dart';

class AddChapterPage extends StatefulWidget {
  final int chapterNumber;
  final String? initialTitle;
  final String? initialContent;
  final bool isEdit;

  const AddChapterPage({
    super.key,
    required this.chapterNumber,
    this.initialTitle,
    this.initialContent,
    this.isEdit = false,
  });

  @override
  State<AddChapterPage> createState() => _AddChapterPageState();
}

class _AddChapterPageState extends State<AddChapterPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle ?? 'Chapter ${widget.chapterNumber}',
    );
    _contentController = TextEditingController(
      text: widget.initialContent ?? '',
    );
    
    // Initialize word count
    _updateWordCount();
    
    // Add listener to update word count as user types
    _contentController.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _wordCount = 0;
      });
    } else {
      final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
      setState(() {
        _wordCount = words.length;
      });
    }
  }

  void _saveChapter() {
    if (_formKey.currentState!.validate()) {
      // Return the chapter data to the previous screen
      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
      });
    }
  }

  void _cancelEditing() {
    // Show confirmation dialog if there are unsaved changes
    final hasChanges = (_titleController.text.trim() != (widget.initialTitle ?? 'Chapter ${widget.chapterNumber}')) ||
                      (_contentController.text.trim() != (widget.initialContent ?? ''));
    
    if (hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Are you sure you want to go back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Top section with minimal padding
            Container(
              padding: const EdgeInsets.fromLTRB(8, 40, 8, 8),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: _cancelEditing,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  
                  // Chapter title input (small and compact)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextFormField(
                        controller: _titleController,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Chapter Title',
                          border: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a chapter title';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  
                  // Word count in top right corner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_wordCount words',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content area - full scrollable text editor
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Start writing your chapter...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter chapter content';
                    }
                    return null;
                  },
                ),
              ),
            ),
            
            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelEditing,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChapter,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.isEdit ? 'Update' : 'Add Chapter',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
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