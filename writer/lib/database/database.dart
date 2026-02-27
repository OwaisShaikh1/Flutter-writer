import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users_table.dart';
import 'tables/items_table.dart';
import 'tables/chapters_table.dart';
import 'tables/user_activity_table.dart';
import 'tables/sync_log_table.dart';
import 'tables/comments_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Users, Items, Chapters, UserActivity, SyncLog, Comments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  // Migration strategy
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema upgrades
        if (from < 2) {
          // Add authorId column to items table
          await m.addColumn(items, items.authorId);
        }
        if (from < 3) {
          // Clean up duplicate chapters (keep the one with lowest id)
          await customStatement('''
            DELETE FROM chapters WHERE id NOT IN (
              SELECT MIN(id) FROM chapters GROUP BY item_id, number
            )
          ''');
        }
        if (from < 4) {
          // Create sync_log table for tracking local changes
          await m.createTable(syncLog);
        }
        if (from < 5) {
          // Add likes count and user like status to items, create comments table
          await m.addColumn(items, items.likesCount);
          await m.addColumn(items, items.isLikedByUser);
          await m.createTable(comments);
        }
        if (from < 6) {
          // Add serverId column to separate local IDs from backend IDs.
          // Use raw SQL because Drift 2.x m.addColumn() doesn't accept nullable columns.
          await customStatement('ALTER TABLE items ADD COLUMN server_id INTEGER');
          // For existing synced items, set serverId = id (they were previously
          // synced using the old key-swap mechanism, so their id IS the backend id)
          await customStatement('UPDATE items SET server_id = id WHERE is_synced = 1');
        }
        if (from < 7) {
          // Add userId column to sync_log for multi-user support
          await customStatement('ALTER TABLE sync_log ADD COLUMN user_id INTEGER');
        }
      },
    );
  }

  /// Clear all user data from all tables (for logout)
  /// This removes items, chapters, comments, sync logs, user activity, and users
  Future<void> clearAllUserData() async {
    await delete(chapters).go();
    await delete(comments).go();
    await delete(syncLog).go();
    await delete(userActivity).go();
    await delete(items).go();
    await delete(users).go();
  }
}

// Opens/creates the SQLite database file on device
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Get app's document directory (e.g., /data/user/0/com.yourapp/files/)
    final dbFolder = await getApplicationDocumentsDirectory();
    
    // Create SQLite database file: writer_app.db
    final file = File(p.join(dbFolder.path, 'writer_app.db'));
    
    // Return connection to SQLite database
    return NativeDatabase(file);
  });
}
