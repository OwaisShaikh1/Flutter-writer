import '../../models/chapter.dart';
import '../../models/literature_item.dart';
import 'novel_export_service.dart';

class _NovelExportServiceStub implements NovelExportService {
  @override
  Future<NovelExportResult> exportNovel({
    required LiteratureItem item,
    required List<Chapter> chapters,
  }) async {
    return const NovelExportResult(
      success: false,
      message: 'Export is not supported on this platform.',
    );
  }
}

NovelExportService createNovelExportServiceImpl() => _NovelExportServiceStub();
