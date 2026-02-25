import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/user_activity_table.dart';

part 'user_activity_dao.g.dart';

@DriftAccessor(tables: [UserActivity])
class UserActivityDao extends DatabaseAccessor<AppDatabase> with _$UserActivityDaoMixin {
  UserActivityDao(AppDatabase db) : super(db);

  // Get activity for an item
  Future<UserActivityEntity?> getActivityForItem(int itemId) =>
      (select(userActivity)..where((t) => t.itemId.equals(itemId))).getSingleOrNull();

  // Watch activity for an item
  Stream<UserActivityEntity?> watchActivityForItem(int itemId) =>
      (select(userActivity)..where((t) => t.itemId.equals(itemId))).watchSingleOrNull();

  // Get all activities (reading history)
  Future<List<UserActivityEntity>> getAllActivities() =>
      (select(userActivity)..orderBy([(t) => OrderingTerm.desc(t.lastReadAt)])).get();

  // Watch all activities
  Stream<List<UserActivityEntity>> watchAllActivities() =>
      (select(userActivity)..orderBy([(t) => OrderingTerm.desc(t.lastReadAt)])).watch();

  // Insert or update activity
  Future<int> upsertActivity(UserActivityCompanion activity) =>
      into(userActivity).insertOnConflictUpdate(activity);

  // Update reading progress
  Future<void> updateReadingProgress({
    required int itemId,
    required int lastChapterRead,
    required int currentPage,
    required double progressPercent,
  }) async {
    final existing = await getActivityForItem(itemId);
    
    if (existing != null) {
      await (update(userActivity)..where((t) => t.itemId.equals(itemId))).write(
        UserActivityCompanion(
          lastChapterRead: Value(lastChapterRead),
          currentPage: Value(currentPage),
          progressPercent: Value(progressPercent),
          lastReadAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(userActivity).insert(
        UserActivityCompanion(
          itemId: Value(itemId),
          lastChapterRead: Value(lastChapterRead),
          currentPage: Value(currentPage),
          progressPercent: Value(progressPercent),
          lastReadAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // Add note to item
  Future<void> addNote(int itemId, String note) async {
    final existing = await getActivityForItem(itemId);
    
    if (existing != null) {
      await (update(userActivity)..where((t) => t.itemId.equals(itemId))).write(
        UserActivityCompanion(notes: Value(note)),
      );
    } else {
      await into(userActivity).insert(
        UserActivityCompanion(
          itemId: Value(itemId),
          notes: Value(note),
        ),
      );
    }
  }

  // Delete activity
  Future<int> deleteActivity(int itemId) =>
      (delete(userActivity)..where((t) => t.itemId.equals(itemId))).go();

  // Clear all activities
  Future<void> clearAllActivities() => delete(userActivity).go();
}
