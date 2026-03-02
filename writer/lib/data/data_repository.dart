import '../database/database.dart';
import 'literature_data.dart';
import 'chapter_data.dart';
import 'comment_data.dart';

/// Main Data Repository - combines all data logic classes
/// Use this as a single entry point for all data operations
class DataRepository {
  static DataRepository? _instance;
  static AppDatabase? _database;

  late final LiteratureData literature;
  late final ChapterData chapters;
  late final CommentData comments;

  DataRepository._(AppDatabase db) {
    literature = LiteratureData(db);
    chapters = ChapterData(db);
    comments = CommentData(db);
  }

  /// Get singleton instance
  static DataRepository get instance {
    if (_instance == null) {
      _database ??= AppDatabase();
      _instance = DataRepository._(_database!);
    }
    return _instance!;
  }

  /// Initialize with custom database (for testing)
  static DataRepository initWithDatabase(AppDatabase db) {
    _database = db;
    _instance = DataRepository._(db);
    return _instance!;
  }

  /// Get raw database access (for advanced operations)
  AppDatabase get database => _database!;

  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    await _database?.clearAllUserData();
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _database?.close();
    _database = null;
    _instance = null;
  }
}
