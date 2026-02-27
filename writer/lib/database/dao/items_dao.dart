import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/items_table.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [Items])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(AppDatabase db) : super(db);

  // Get all items
  Future<List<ItemEntity>> getAllItems() => select(items).get();

  // Get items as stream (reactive)
  Stream<List<ItemEntity>> watchAllItems() => select(items).watch();

  // Get item by ID
  Future<ItemEntity?> getItemById(int id) =>
      (select(items)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Search items
  Stream<List<ItemEntity>> searchItems(String query) {
    return (select(items)
          ..where((t) => t.name.contains(query) | t.author.contains(query)))
        .watch();
  }

  // Filter by type
  Stream<List<ItemEntity>> getItemsByType(String type) {
    return (select(items)..where((t) => t.type.equals(type))).watch();
  }

  // Get favorites
  Stream<List<ItemEntity>> getFavorites() {
    return (select(items)..where((t) => t.isFavorite.equals(true))).watch();
  }

  // Insert or update item
  Future<int> upsertItem(ItemsCompanion item) =>
      into(items).insertOnConflictUpdate(item);

  // Batch insert
  Future<void> insertItems(List<ItemsCompanion> itemsList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(items, itemsList);
    });
  }

  // Toggle favorite
  Future<void> toggleFavorite(int id, bool isFav) =>
      (update(items)..where((t) => t.id.equals(id)))
          .write(ItemsCompanion(isFavorite: Value(isFav)));

  // Mark as synced
  Future<void> markAsSynced(int id) =>
      (update(items)..where((t) => t.id.equals(id))).write(ItemsCompanion(
        isSynced: const Value(true),
        lastSyncedAt: Value(DateTime.now()),
      ));

  // Get unsynced items (for push to backend)
  Future<List<ItemEntity>> getUnsyncedItems() =>
      (select(items)..where((t) => t.isSynced.equals(false))).get();

  // Delete item
  Future<int> deleteItem(int id) =>
      (delete(items)..where((t) => t.id.equals(id))).go();

  // Clear all items
  Future<void> clearAllItems() => delete(items).go();

  // Get items by author ID (for "My Works" feature)
  Stream<List<ItemEntity>> watchItemsByAuthorId(int authorId) {
    return (select(items)..where((t) => t.authorId.equals(authorId))).watch();
  }

  // Get items by author ID (non-stream)
  Future<List<ItemEntity>> getItemsByAuthorId(int authorId) {
    return (select(items)..where((t) => t.authorId.equals(authorId))).get();
  }

  // Check if user owns an item
  Future<bool> isItemOwnedByUser(int itemId, int authorId) async {
    final item = await getItemById(itemId);
    return item?.authorId == authorId;
  }

  // Update item (for editing)
  Future<void> updateItem(int id, ItemsCompanion companion) =>
      (update(items)..where((t) => t.id.equals(id))).write(companion);

  // Change item ID (used when syncing local item to backend ID)
  // This creates a new row with the new ID and deletes the old one
  // DEPRECATED: Use setServerId() instead to avoid duplicate-item bugs
  Future<void> changeItemId(int oldId, int newId, ItemEntity item) async {
    await into(items).insert(ItemsCompanion(
      id: Value(newId),
      name: Value(item.name),
      author: Value(item.author),
      authorId: item.authorId != null ? Value(item.authorId!) : const Value.absent(),
      type: Value(item.type),
      rating: Value(item.rating),
      chaptersCount: Value(item.chaptersCount),
      commentsCount: Value(item.commentsCount),
      likesCount: Value(item.likesCount),
      isLikedByUser: Value(item.isLikedByUser),
      imageUrl: Value(item.imageUrl),
      imageLocalPath: Value(item.imageLocalPath),
      description: Value(item.description),
      isFavorite: Value(item.isFavorite),
      isSynced: const Value(true),
      lastSyncedAt: Value(DateTime.now()),
      createdAt: Value(item.createdAt),
    ));
    // Old item will be deleted after chapters are migrated
  }

  // ==================== SERVER ID MANAGEMENT ====================

  /// Set the backend-assigned server ID on a local item after a successful sync.
  /// The local [id] never changes — only [serverId] is added.
  Future<void> setServerId(int localId, int serverIdValue) =>
      (update(items)..where((t) => t.id.equals(localId))).write(ItemsCompanion(
        serverId: Value(serverIdValue),
        isSynced: const Value(true),
        lastSyncedAt: Value(DateTime.now()),
      ));

  /// Get the backend server ID for a local item (null if not yet synced).
  ///
  /// Legacy fallback: items created before v6 (old key-swap era) have their
  /// SQLite id equal to the backend id. If [serverId] is null but [isSynced]
  /// is true, return [id] so that old items continue working without a migration.
  Future<int?> getServerId(int localId) async {
    final item = await getItemById(localId);
    if (item == null) return null;
    if (item.serverId != null) return item.serverId;
    // Legacy fallback: synced item created before the serverId column existed.
    // In the old system id == backend id after the key-swap.
    if (item.isSynced) {
      // Persist the serverId so future lookups don't need this fallback.
      await setServerId(localId, item.id);
      return item.id;
    }
    return null;
  }

  /// Find a local item by its backend server ID.
  /// Used during pull-sync to avoid creating duplicates.
  Future<ItemEntity?> getItemByServerId(int serverIdValue) =>
      (select(items)..where((t) => t.serverId.equals(serverIdValue)))
          .getSingleOrNull();

  /// Get all items that have been synced to the server (have a server_id).
  /// Used to detect deletions: if an item has a server_id but is no longer
  /// on the server, it should be deleted locally.
  Future<List<ItemEntity>> getSyncedItems() =>
      (select(items)..where((t) => t.serverId.isNotNull()))
          .get();

  // Update like status for an item
  Future<void> updateLikeStatus(int id, bool isLiked, int likesCount) =>
      (update(items)..where((t) => t.id.equals(id))).write(ItemsCompanion(
        isLikedByUser: Value(isLiked),
        likesCount: Value(likesCount),
      ));

  // Toggle like for an item locally
  Future<void> toggleLike(int id) async {
    final item = await getItemById(id);
    if (item != null) {
      final newLiked = !item.isLikedByUser;
      final newCount = newLiked ? item.likesCount + 1 : item.likesCount - 1;
      await updateLikeStatus(id, newLiked, newCount < 0 ? 0 : newCount);
    }
  }
}
