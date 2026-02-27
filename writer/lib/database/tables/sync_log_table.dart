import 'package:drift/drift.dart';

/// Tracks local changes that need to be synced to the backend.
/// Each operation (CREATE/UPDATE/DELETE) on items or chapters creates a log entry.
@DataClassName('SyncLogEntry')
class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  /// The user ID who made this change (for multi-user support)
  IntColumn get userId => integer().nullable()();
  
  /// Type of entity: 'item' or 'chapter'
  TextColumn get entityType => text()();
  
  /// The ID of the entity (local ID for new items, backend ID for existing)
  IntColumn get entityId => integer()();
  
  /// For chapters: the parent item ID
  IntColumn get parentId => integer().nullable()();
  
  /// Operation type: 'create', 'update', 'delete'
  TextColumn get operation => text()();
  
  /// JSON payload with the data to sync
  TextColumn get payload => text()();
  
  /// When this change was made
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Number of sync attempts (for retry logic)
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  
  /// Last error message if sync failed
  TextColumn get lastError => text().nullable()();
}
