import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/dao/items_dao.dart';
import '../models/literature_item.dart';

/// Minimal data logic for Literature (Create, Read, Update, Delete)
class LiteratureData {
  final AppDatabase _db;
  late final ItemsDao _itemsDao;

  LiteratureData(this._db) {
    _itemsDao = ItemsDao(_db);
  }

  // ==================== CREATE ====================

  /// Create a new literature item
  Future<int> createLiterature({
    required String title,
    required String author,
    required String type,
    required String description,
    int? authorId,
    String? imageUrl,
  }) async {
    final companion = ItemsCompanion(
      name: Value(title),
      author: Value(author),
      type: Value(type),
      description: Value(description),
      authorId: authorId != null ? Value(authorId) : const Value.absent(),
      imageUrl: imageUrl != null ? Value(imageUrl) : const Value.absent(),
      isSynced: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return await _itemsDao.upsertItem(companion);
  }

  // ==================== READ ====================

  /// Get all literature items
  Future<List<LiteratureItem>> getAllLiterature() async {
    final entities = await _itemsDao.getAllItems();
    return entities.map(_entityToModel).toList();
  }

  /// Watch all literature items (reactive stream)
  Stream<List<LiteratureItem>> watchAllLiterature() {
    return _itemsDao.watchAllItems().map(
          (entities) => entities.map(_entityToModel).toList(),
        );
  }

  /// Get literature by ID
  Future<LiteratureItem?> getLiteratureById(int id) async {
    final entity = await _itemsDao.getItemById(id);
    return entity != null ? _entityToModel(entity) : null;
  }

  /// Get literature by author ID
  Future<List<LiteratureItem>> getLiteratureByAuthor(int authorId) async {
    final entities = await _itemsDao.getItemsByAuthorId(authorId);
    return entities.map(_entityToModel).toList();
  }

  /// Watch literature by author ID (reactive)
  Stream<List<LiteratureItem>> watchLiteratureByAuthor(int authorId) {
    return _itemsDao.watchItemsByAuthorId(authorId).map(
          (entities) => entities.map(_entityToModel).toList(),
        );
  }

  /// Search literature by query
  Stream<List<LiteratureItem>> searchLiterature(String query) {
    return _itemsDao.searchItems(query).map(
          (entities) => entities.map(_entityToModel).toList(),
        );
  }

  /// Get favorites
  Stream<List<LiteratureItem>> watchFavorites() {
    return _itemsDao.getFavorites().map(
          (entities) => entities.map(_entityToModel).toList(),
        );
  }

  /// Get literature by type
  Stream<List<LiteratureItem>> watchLiteratureByType(String type) {
    return _itemsDao.getItemsByType(type).map(
          (entities) => entities.map(_entityToModel).toList(),
        );
  }

  // ==================== UPDATE ====================

  /// Update literature item
  Future<void> updateLiterature({
    required int id,
    String? title,
    String? author,
    String? type,
    String? description,
    String? imageUrl,
    double? rating,
  }) async {
    final companion = ItemsCompanion(
      name: title != null ? Value(title) : const Value.absent(),
      author: author != null ? Value(author) : const Value.absent(),
      type: type != null ? Value(type) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      imageUrl: imageUrl != null ? Value(imageUrl) : const Value.absent(),
      rating: rating != null ? Value(rating) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
      hasChanged: const Value(true),
    );
    await _itemsDao.updateItem(id, companion);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    await _itemsDao.toggleFavorite(id, isFavorite);
  }

  /// Update chapter count
  Future<void> updateChapterCount(int id, int count) async {
    await _itemsDao.updateItem(
      id,
      ItemsCompanion(
        chaptersCount: Value(count),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update comment count
  Future<void> updateCommentCount(int id, int count) async {
    await _itemsDao.updateItem(
      id,
      ItemsCompanion(
        commentsCount: Value(count),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ==================== DELETE ====================

  /// Delete literature by ID
  Future<void> deleteLiterature(int id) async {
    await _itemsDao.deleteItem(id);
  }

  /// Delete all literature
  Future<void> deleteAllLiterature() async {
    await _itemsDao.clearAllItems();
  }

  // ==================== HELPERS ====================

  /// Convert database entity to model
  LiteratureItem _entityToModel(ItemEntity entity) {
    return LiteratureItem(
      id: entity.id,
      title: entity.name,
      author: entity.author,
      authorId: entity.authorId,
      type: entity.type,
      rating: entity.rating,
      chapters: entity.chaptersCount,
      comments: entity.commentsCount,
      likes: entity.likesCount,
      isLikedByUser: entity.isLikedByUser,
      imageUrl: entity.imageUrl,
      imageLocalPath: entity.imageLocalPath,
      description: entity.description,
      isFavorite: entity.isFavorite,
      isSynced: entity.isSynced,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
