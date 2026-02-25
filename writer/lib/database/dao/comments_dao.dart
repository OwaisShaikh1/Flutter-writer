import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/comments_table.dart';

part 'comments_dao.g.dart';

@DriftAccessor(tables: [Comments])
class CommentsDao extends DatabaseAccessor<AppDatabase> with _$CommentsDaoMixin {
  CommentsDao(AppDatabase db) : super(db);

  // Get all comments for an item
  Future<List<CommentEntity>> getCommentsForItem(int itemId) =>
      (select(comments)
            ..where((t) => t.itemId.equals(itemId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  // Watch comments for an item (reactive)
  Stream<List<CommentEntity>> watchCommentsForItem(int itemId) =>
      (select(comments)
            ..where((t) => t.itemId.equals(itemId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  // Get comment by ID
  Future<CommentEntity?> getCommentById(int id) =>
      (select(comments)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Get comment by remote ID
  Future<CommentEntity?> getCommentByRemoteId(int remoteId) =>
      (select(comments)..where((t) => t.remoteId.equals(remoteId))).getSingleOrNull();

  // Insert a comment
  Future<int> insertComment(CommentsCompanion comment) =>
      into(comments).insert(comment);

  // Insert or update comment
  Future<int> upsertComment(CommentsCompanion comment) =>
      into(comments).insertOnConflictUpdate(comment);

  // Batch insert comments
  Future<void> insertComments(List<CommentsCompanion> commentsList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(comments, commentsList);
    });
  }

  // Update comment
  Future<bool> updateComment(int id, CommentsCompanion comment) async {
    final count = await (update(comments)..where((t) => t.id.equals(id))).write(comment);
    return count > 0;
  }

  // Delete comment by ID
  Future<int> deleteComment(int id) =>
      (delete(comments)..where((t) => t.id.equals(id))).go();

  // Delete comment by remote ID
  Future<int> deleteCommentByRemoteId(int remoteId) =>
      (delete(comments)..where((t) => t.remoteId.equals(remoteId))).go();

  // Delete all comments for an item
  Future<int> deleteCommentsForItem(int itemId) =>
      (delete(comments)..where((t) => t.itemId.equals(itemId))).go();

  // Get comments count for an item
  Future<int> getCommentsCount(int itemId) async {
    final result = await (select(comments)..where((t) => t.itemId.equals(itemId))).get();
    return result.length;
  }

  // Watch comments count for an item
  Stream<int> watchCommentsCount(int itemId) {
    return (select(comments)..where((t) => t.itemId.equals(itemId)))
        .watch()
        .map((list) => list.length);
  }

  // Get unsynced comments (for push to backend)
  Future<List<CommentEntity>> getUnsyncedComments() =>
      (select(comments)..where((t) => t.isSynced.equals(false))).get();

  // Mark comment as synced
  Future<void> markAsSynced(int id) =>
      (update(comments)..where((t) => t.id.equals(id)))
          .write(const CommentsCompanion(isSynced: Value(true)));

  // Clear all comments
  Future<void> clearAllComments() => delete(comments).go();
}
