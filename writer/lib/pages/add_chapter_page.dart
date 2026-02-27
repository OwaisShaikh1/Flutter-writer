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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _cancelEditing,
          icon: const Icon(Icons.close_rounded, size: 20),
        ),
        title: Text(
          widget.isEdit ? 'EDIT CHAPTER' : 'NEW CHAPTER',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saveChapter,
              child: Text(
                'DONE',
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
        child: Column(
          children: [
            // Chapter title input (naked)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Chapter Title',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
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
            
            // Subtle word count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    '$_wordCount WORDS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Main content area - naked text editor
            Expanded(
              child: TextFormField(
                controller: _contentController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  height: 1.8,
                  fontSize: 18,
                  letterSpacing: 0.1,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing your story...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter chapter content';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}