import 'package:drift/drift.dart';

@DataClassName('ItemEntity')
class Items extends Table {
  IntColumn get id => integer().autoIncrement()(); // Local SQLite ID (never changes)
  IntColumn get serverId => integer().nullable()(); // Backend-assigned ID (null until synced)
  TextColumn get name => text()();
  TextColumn get author => text()();
  IntColumn get authorId => integer().nullable()(); // User ID who created this
  TextColumn get type => text()(); // Drama, Poetry, Novel
  RealColumn get rating => real().withDefault(const Constant(0.0))();
  IntColumn get chaptersCount => integer().withDefault(const Constant(0))();
  IntColumn get commentsCount => integer().withDefault(const Constant(0))();
  IntColumn get likesCount => integer().withDefault(const Constant(0))();
  BoolColumn get isLikedByUser => boolean().withDefault(const Constant(false))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get imageLocalPath => text().nullable()(); // For offline images
  TextColumn get description => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
