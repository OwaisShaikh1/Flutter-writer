import 'package:drift/drift.dart';
import 'items_table.dart';

@DataClassName('ChapterEntity')
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get number => integer()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {itemId, number}, // Prevent duplicate chapters
      ];
}
