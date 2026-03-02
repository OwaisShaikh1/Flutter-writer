import 'package:drift/drift.dart';
import 'items_table.dart';

@DataClassName('ChapterEntity')
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get number => integer()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get hasChanged => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))(); // For conflict resolution
  
  @override
  List<Set<Column>> get uniqueKeys => [
        {itemId, number}, // Prevent duplicate chapters
      ];
}
