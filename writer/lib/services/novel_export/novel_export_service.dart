import '../../models/chapter.dart';
import '../../models/literature_item.dart';
import 'novel_export_service_stub.dart'
    if (dart.library.io) 'novel_export_service_io.dart'
    if (dart.library.html) 'novel_export_service_web.dart';

class NovelExportResult {
  final bool success;
  final String message;
  final String? filePath;

  const NovelExportResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}

abstract class NovelExportService {
  Future<NovelExportResult> exportNovel({
    required LiteratureItem item,
    required List<Chapter> chapters,
  });
}

NovelExportService createNovelExportService() => createNovelExportServiceImpl();
