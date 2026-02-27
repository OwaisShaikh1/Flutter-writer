import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/sync_log_table.dart';

part 'sync_log_dao.g.dart';

@DriftAccessor(tables: [SyncLog])
class SyncLogDao extends DatabaseAccessor<AppDatabase> with _$SyncLogDaoMixin {
  SyncLogDao(AppDatabase db) : super(db);

  // Log a CREATE operation for an item
  Future<void> logItemCreate(int localId, Map<String, dynamic> data, {int? userId}) async {
    await into(syncLog).insert(SyncLogCompanion(
      userId: Value(userId),
      entityType: const Value('item'),
      entityId: Value(localId),
      operation: const Value('create'),
      payload: Value(jsonEncode(data)),
    ));
  }

  // Log an UPDATE operation for an item
  Future<void> logItemUpdate(int itemId, Map<String, dynamic> data, {int? userId}) async {
    // Remove any pending create for this item (if exists, combine into one create)
    final existingCreate = await (select(syncLog)
          ..where((t) => t.entityType.equals('item') & 
                         t.entityId.equals(itemId) & 
                         t.operation.equals('create')))
        .getSingleOrNull();
    
    if (existingCreate != null) {
      // Update the existing create payload with new data
      final existingData = jsonDecode(existingCreate.payload) as Map<String, dynamic>;
      existingData.addAll(data);
      await (update(syncLog)..where((t) => t.id.equals(existingCreate.id)))
          .write(SyncLogCompanion(payload: Value(jsonEncode(existingData))));
    } else {
      // Log as update
      await into(syncLog).insert(SyncLogCompanion(
        userId: Value(userId),
        entityType: const Value('item'),
        entityId: Value(itemId),
        operation: const Value('update'),
        payload: Value(jsonEncode(data)),
      ));
    }
  }

  // Log a DELETE operation for an item
  Future<void> logItemDelete(int itemId, {int? userId}) async {
    // Remove any pending creates/updates for this item
    await (delete(syncLog)
          ..where((t) => t.entityType.equals('item') & t.entityId.equals(itemId)))
        .go();
    
    // Also remove any pending chapter operations for this item
    await (delete(syncLog)
          ..where((t) => t.entityType.equals('chapter') & t.parentId.equals(itemId)))
        .go();
    
    // Log the delete
    await into(syncLog).insert(SyncLogCompanion(
      userId: Value(userId),
      entityType: const Value('item'),
      entityId: Value(itemId),
      operation: const Value('delete'),
      payload: const Value('{}'),
    ));
  }

  // Log a CREATE operation for a chapter
  Future<void> logChapterCreate(int chapterId, int itemId, Map<String, dynamic> data, {int? userId}) async {
    await into(syncLog).insert(SyncLogCompanion(
      userId: Value(userId),
      entityType: const Value('chapter'),
      entityId: Value(chapterId),
      parentId: Value(itemId),
      operation: const Value('create'),
      payload: Value(jsonEncode(data)),
    ));
  }

  // Log an UPDATE operation for a chapter
  Future<void> logChapterUpdate(int chapterId, int itemId, Map<String, dynamic> data, {int? userId}) async {
    // Check if there's a pending create for this chapter
    final existingCreate = await (select(syncLog)
          ..where((t) => t.entityType.equals('chapter') & 
                         t.entityId.equals(chapterId) & 
                         t.operation.equals('create')))
        .getSingleOrNull();
    
    if (existingCreate != null) {
      // Update the existing create payload
      final existingData = jsonDecode(existingCreate.payload) as Map<String, dynamic>;
      existingData.addAll(data);
      await (update(syncLog)..where((t) => t.id.equals(existingCreate.id)))
          .write(SyncLogCompanion(payload: Value(jsonEncode(existingData))));
    } else {
      await into(syncLog).insert(SyncLogCompanion(
        userId: Value(userId),
        entityType: const Value('chapter'),
        entityId: Value(chapterId),
        parentId: Value(itemId),
        operation: const Value('update'),
        payload: Value(jsonEncode(data)),
      ));
    }
  }

  // Log a DELETE operation for a chapter
  // chapterNumber must be supplied so the sync log processor can find and
  // delete the correct row on the backend (it uses payload['number']).
  Future<void> logChapterDelete(int chapterId, int itemId, int chapterNumber, {int? userId}) async {
    // Remove any pending creates/updates for this chapter
    await (delete(syncLog)
          ..where((t) => t.entityType.equals('chapter') & t.entityId.equals(chapterId)))
        .go();
    
    // Log the delete with the chapter number in the payload
    await into(syncLog).insert(SyncLogCompanion(
      userId: Value(userId),
      entityType: const Value('chapter'),
      entityId: Value(chapterId),
      parentId: Value(itemId),
      operation: const Value('delete'),
      payload: Value(jsonEncode({'number': chapterNumber})),
    ));
  }

  // Get all pending sync operations (ordered by creation time)
  Future<List<SyncLogEntry>> getPendingOperations() =>
      (select(syncLog)..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();

  // Get pending operations for a specific user (ordered by creation time)
  Future<List<SyncLogEntry>> getPendingOperationsForUser(int userId) =>
      (select(syncLog)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
      .get();

  // Get pending operations count
  Future<int> getPendingCount() async {
    final count = countAll();
    final query = selectOnly(syncLog)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // Get pending operations count for a specific user
  Future<int> getPendingCountForUser(int userId) async {
    final count = countAll();
    final query = selectOnly(syncLog)
      ..addColumns([count])
      ..where(syncLog.userId.equals(userId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // Watch pending operations count (reactive)
  Stream<int> watchPendingCount() {
    final count = countAll();
    final query = selectOnly(syncLog)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  // Watch pending operations count for a specific user (reactive)
  Stream<int> watchPendingCountForUser(int userId) {
    final count = countAll();
    final query = selectOnly(syncLog)
      ..addColumns([count])
      ..where(syncLog.userId.equals(userId));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  // Mark operation as attempted (increment attempts, set error)
  Future<void> markAttempted(int id, String? error) async {
    final entry = await (select(syncLog)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (entry != null) {
      await (update(syncLog)..where((t) => t.id.equals(id))).write(SyncLogCompanion(
        attempts: Value(entry.attempts + 1),
        lastError: Value(error),
      ));
    }
  }

  // Remove a completed operation
  Future<void> removeOperation(int id) =>
      (delete(syncLog)..where((t) => t.id.equals(id))).go();

  // Clear all pending operations
  Future<void> clearAll() => delete(syncLog).go();

  // Update entity ID after backend assigns real ID (for new items)
  Future<void> updateEntityId(int logId, int newEntityId) =>
      (update(syncLog)..where((t) => t.id.equals(logId)))
          .write(SyncLogCompanion(entityId: Value(newEntityId)));
}
