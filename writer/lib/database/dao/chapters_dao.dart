import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/chapters_table.dart';

part 'chapters_dao.g.dart';

@DriftAccessor(tables: [Chapters])
class ChaptersDao extends DatabaseAccessor<AppDatabase> with _$ChaptersDaoMixin {
  ChaptersDao(AppDatabase db) : super(db);

  // Get all chapters for an item
  Stream<List<ChapterEntity>> watchChaptersByItemId(int itemId) {
    return (select(chapters)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm(expression: t.number)]))
        .watch();
  }

  // Get chapters for an item (non-stream)
  Future<List<ChapterEntity>> getChaptersByItemId(int itemId) {
    return (select(chapters)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm(expression: t.number)]))
        .get();
  }

  // Get specific chapter
  Future<ChapterEntity?> getChapter(int itemId, int chapterNumber) async {
    final results = await (select(chapters)
          ..where((t) => t.itemId.equals(itemId) & t.number.equals(chapterNumber))
          ..limit(1))
        .get();
    return results.isEmpty ? null : results.first;
  }

  // Insert or update chapter (handles UNIQUE constraint on itemId + number)
  Future<int> upsertChapter(ChaptersCompanion chapter) async {
    // Check if a chapter with this itemId and number already exists
    if (chapter.itemId.present && chapter.number.present) {
      final existing = await getChapter(chapter.itemId.value, chapter.number.value);
      if (existing != null) {
        // Update existing chapter
        await (update(chapters)..where((t) => t.id.equals(existing.id))).write(chapter);
        return existing.id;
      }
    }
    // Insert new chapter
    return await into(chapters).insert(chapter);
  }

  // Batch insert chapters
  Future<void> insertChapters(List<ChaptersCompanion> chaptersList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(chapters, chaptersList);
    });
  }

  // Mark chapter as downloaded
  Future<void> markAsDownloaded(int itemId, int chapterNumber) =>
      (update(chapters)
            ..where((t) => t.itemId.equals(itemId) & t.number.equals(chapterNumber)))
          .write(ChaptersCompanion(
        isDownloaded: const Value(true),
        downloadedAt: Value(DateTime.now()),
      ));

  // Get downloaded chapters count
  Future<int> getDownloadedChaptersCount(int itemId) async {
    final count = countAll();
    final query = selectOnly(chapters)
      ..addColumns([count])
      ..where(chapters.itemId.equals(itemId) & chapters.isDownloaded.equals(true));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // Delete all chapters for an item
  Future<void> deleteChaptersByItemId(int itemId) =>
      (delete(chapters)..where((t) => t.itemId.equals(itemId))).go();

  // Delete a specific chapter by itemId and number
  Future<void> deleteChapter(int itemId, int chapterNumber) =>
      (delete(chapters)..where((t) => t.itemId.equals(itemId) & t.number.equals(chapterNumber))).go();

  // Update itemId for all chapters (used when syncing local item to backend ID)
  Future<void> updateChaptersItemId(int oldItemId, int newItemId) =>
      (update(chapters)..where((t) => t.itemId.equals(oldItemId)))
          .write(ChaptersCompanion(itemId: Value(newItemId)));

  // Clear all chapters (for logout)
  Future<void> clearAllChapters() => delete(chapters).go();
}
