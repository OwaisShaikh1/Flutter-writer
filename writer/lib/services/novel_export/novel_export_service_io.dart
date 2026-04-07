import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../models/chapter.dart';
import '../../models/literature_item.dart';
import 'novel_export_service.dart';

class _NovelExportServiceIo implements NovelExportService {
  @override
  Future<NovelExportResult> exportNovel({
    required LiteratureItem item,
    required List<Chapter> chapters,
  }) async {
    if (chapters.isEmpty) {
      return const NovelExportResult(
        success: false,
        message: 'No chapters found to export.',
      );
    }

    final sorted = [...chapters]..sort((a, b) => a.number.compareTo(b.number));

    try {
      final markdown = _buildMarkdown(item: item, chapters: sorted);
      final safeTitle = _sanitizeFileName(item.title.isEmpty ? 'untitled' : item.title);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final suggestedName = '${safeTitle}_$timestamp.md';

      if (Platform.isAndroid || Platform.isIOS) {
        final selectedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Choose where to save your export',
          fileName: suggestedName,
          type: FileType.custom,
          allowedExtensions: ['md'],
          bytes: Uint8List.fromList(utf8.encode(markdown)),
        );

        if (selectedPath == null) {
          return const NovelExportResult(
            success: false,
            message: 'Export cancelled. No file was saved.',
          );
        }

        return NovelExportResult(
          success: true,
          message: 'Novel exported successfully.',
          filePath: selectedPath,
        );
      }

      final selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Choose where to save your export',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['md'],
      );

      if (selectedPath == null) {
        return const NovelExportResult(
          success: false,
          message: 'Export cancelled. No file was saved.',
        );
      }

      final outputPath = p.extension(selectedPath).isEmpty
          ? '$selectedPath.md'
          : selectedPath;
      final outFile = File(outputPath);

      await outFile.writeAsString(markdown, flush: true);

      return NovelExportResult(
        success: true,
        message: 'Novel exported successfully.',
        filePath: outFile.path,
      );
    } catch (e) {
      return NovelExportResult(
        success: false,
        message: 'Failed to export novel: $e',
      );
    }
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    if (sanitized.isEmpty) return 'untitled_novel';
    return sanitized;
  }

  String _buildMarkdown({
    required LiteratureItem item,
    required List<Chapter> chapters,
  }) {
    final markdown = StringBuffer()
      ..writeln('# ${item.title}')
      ..writeln()
      ..writeln('**Author:** ${item.author}')
      ..writeln('**Type:** ${item.type}')
      ..writeln('**Chapters:** ${chapters.length}')
      ..writeln('**Exported At:** ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('---')
      ..writeln()
      ..writeln('> Styled text export: Markdown headings and formatting are preserved.')
      ..writeln();

    for (final chapter in chapters) {
      markdown
        ..writeln('## Chapter ${chapter.number}: ${chapter.title}')
        ..writeln()
        ..writeln(chapter.content)
        ..writeln()
        ..writeln('---')
        ..writeln();
    }

    return markdown.toString();
  }
}

NovelExportService createNovelExportServiceImpl() => _NovelExportServiceIo();
