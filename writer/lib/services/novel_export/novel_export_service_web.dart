import '../../models/chapter.dart';
import '../../models/literature_item.dart';
import 'novel_export_service.dart';

class _NovelExportServiceWeb implements NovelExportService {
  @override
  Future<NovelExportResult> exportNovel({
    required LiteratureItem item,
    required List<Chapter> chapters,
  }) async {
    return const NovelExportResult(
      success: false,
      message: 'Offline file export is not available on web.',
    );
  }
}

NovelExportService createNovelExportServiceImpl() => _NovelExportServiceWeb();
