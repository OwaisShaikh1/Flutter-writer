import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/dao/chapters_dao.dart';
import '../models/chapter.dart';

/// Minimal data logic for Chapters (Create, Read, Update, Delete)
class ChapterData {
  final AppDatabase _db;
  late final ChaptersDao _chaptersDao;

  ChapterData(this._db) {
    _chaptersDao = ChaptersDao(_db);
  }

  // ==================== CREATE ====================

  /// Create a new chapter
  Future<int> createChapter({
    required int itemId,
    required int number,
    required String title,
    required String content,
  }) async {
    final companion = ChaptersCompanion(
      itemId: Value(itemId),
      number: Value(number),
      title: Value(title),
      content: Value(content),
      isDownloaded: const Value(true),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return await _chaptersDao.upsertChapter(companion);
  }

  // ==================== READ ====================

  /// Get all chapters for an item
  Future<List<Chapter>> getChaptersByItemId(int itemId) async {
    final entities = await _chaptersDao.getChaptersByItemId(itemId);
    return entities.map(_entityToModel).toList();
  }

  /// Watch chapters for an item (reactive stream)
  Stream<List<Chapter>> watchChaptersByItemId(int itemId) {
    return _chaptersDao.watchChaptersByItemId(itemId).map(
          (entities) => entities.map(_entityToModel).toList(),
        );
  }

  /// Get a specific chapter by item ID and chapter number
  Future<Chapter?> getChapter(int itemId, int chapterNumber) async {
    final entity = await _chaptersDao.getChapter(itemId, chapterNumber);
    return entity != null ? _entityToModel(entity) : null;
  }

  /// Get chapter count for an item
  Future<int> getChapterCount(int itemId) async {
    final chapters = await _chaptersDao.getChaptersByItemId(itemId);
    return chapters.length;
  }

  /// Get downloaded chapters count
  Future<int> getDownloadedChaptersCount(int itemId) async {
    return await _chaptersDao.getDownloadedChaptersCount(itemId);
  }

  // ==================== UPDATE ====================

  /// Update a chapter
  Future<void> updateChapter({
    required int itemId,
    required int chapterNumber,
    String? title,
    String? content,
  }) async {
    final existing = await _chaptersDao.getChapter(itemId, chapterNumber);
    if (existing == null) return;

    final companion = ChaptersCompanion(
      title: title != null ? Value(title) : const Value.absent(),
      content: content != null ? Value(content) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
      hasChanged: const Value(true),
    );
    await _chaptersDao.upsertChapter(
      companion.copyWith(
        itemId: Value(itemId),
        number: Value(chapterNumber),
      ),
    );
  }

  /// Mark chapter as downloaded
  Future<void> markAsDownloaded(int itemId, int chapterNumber) async {
    await _chaptersDao.markAsDownloaded(itemId, chapterNumber);
  }

  /// Reorder chapters (update chapter numbers)
  Future<void> reorderChapters(int itemId, List<int> newOrder) async {
    final chapters = await _chaptersDao.getChaptersByItemId(itemId);

    for (int i = 0; i < newOrder.length; i++) {
      final oldNumber = newOrder[i];
      final newNumber = i + 1;

      if (oldNumber != newNumber) {
        final chapter = chapters.firstWhere(
          (c) => c.number == oldNumber,
          orElse: () => throw Exception('Chapter not found'),
        );

        await _chaptersDao.upsertChapter(
          ChaptersCompanion(
            id: Value(chapter.id),
            itemId: Value(itemId),
            number: Value(newNumber),
            title: Value(chapter.title),
            content: Value(chapter.content),
            isDownloaded: Value(chapter.isDownloaded),
            updatedAt: Value(DateTime.now()),
            hasChanged: const Value(true),
          ),
        );
      }
    }
  }

  // ==================== DELETE ====================

  /// Delete a specific chapter
  Future<void> deleteChapter(int itemId, int chapterNumber) async {
    await _chaptersDao.deleteChapter(itemId, chapterNumber);
  }

  /// Delete all chapters for an item
  Future<void> deleteAllChaptersForItem(int itemId) async {
    await _chaptersDao.deleteChaptersByItemId(itemId);
  }

  /// Delete all chapters
  Future<void> deleteAllChapters() async {
    await _chaptersDao.clearAllChapters();
  }

  // ==================== HELPERS ====================

  /// Convert database entity to model
  Chapter _entityToModel(ChapterEntity entity) {
    return Chapter(
      id: entity.id,
      itemId: entity.itemId,
      number: entity.number,
      title: entity.title,
      content: entity.content,
      isDownloaded: entity.isDownloaded,
      downloadedAt: entity.downloadedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
