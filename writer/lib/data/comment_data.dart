import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/dao/comments_dao.dart';
import '../models/comment.dart';

/// Minimal data logic for Comments (Create, Read, Update, Delete)
class CommentData {
  final AppDatabase _db;
  late final CommentsDao _commentsDao;

  CommentData(this._db) {
    _commentsDao = CommentsDao(_db);
  }

  // ==================== CREATE ====================

  /// Create a new comment
  Future<int> createComment({
    required int itemId,
    required int userId,
    required String username,
    required String content,
  }) async {
    final companion = CommentsCompanion(
      itemId: Value(itemId),
      userId: Value(userId),
      username: Value(username),
      content: Value(content),
      createdAt: Value(DateTime.now()),
      isSynced: const Value(false),
    );
    return await _commentsDao.insertComment(companion);
  }

  // ==================== READ ====================

  /// Get all comments for an item
  Future<List<Comment>> getCommentsForItem(int itemId) async {
    final entities = await _commentsDao.getCommentsForItem(itemId);
    return entities.map(_entityToModel).toList();
  }

  /// Watch comments for an item (reactive stream)
  Stream<List<Comment>> watchCommentsForItem(int itemId) {
    return _commentsDao.watchCommentsForItem(itemId).map(
          (entities) => entities.map(_entityToModel).toList(),
        );
  }

  /// Get comment by ID
  Future<Comment?> getCommentById(int id) async {
    final entity = await _commentsDao.getCommentById(id);
    return entity != null ? _entityToModel(entity) : null;
  }

  /// Get comments count for an item
  Future<int> getCommentsCount(int itemId) async {
    return await _commentsDao.getCommentsCount(itemId);
  }

  /// Watch comments count (reactive)
  Stream<int> watchCommentsCount(int itemId) {
    return _commentsDao.watchCommentsCount(itemId);
  }

  // ==================== UPDATE ====================

  /// Update a comment
  Future<void> updateComment({
    required int id,
    required String content,
  }) async {
    final companion = CommentsCompanion(
      content: Value(content),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    );
    await _commentsDao.updateComment(id, companion);
  }

  // ==================== DELETE ====================

  /// Delete comment by ID
  Future<void> deleteComment(int id) async {
    await _commentsDao.deleteComment(id);
  }

  /// Delete all comments for an item
  Future<void> deleteCommentsForItem(int itemId) async {
    await _commentsDao.deleteCommentsForItem(itemId);
  }

  /// Delete all comments
  Future<void> deleteAllComments() async {
    await _commentsDao.clearAllComments();
  }

  // ==================== HELPERS ====================

  /// Convert database entity to model
  Comment _entityToModel(CommentEntity entity) {
    return Comment(
      id: entity.id,
      remoteId: entity.remoteId,
      itemId: entity.itemId,
      userId: entity.userId,
      username: entity.username,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: entity.isSynced,
    );
  }
}
