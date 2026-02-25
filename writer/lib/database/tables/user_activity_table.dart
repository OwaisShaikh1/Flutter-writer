import 'package:drift/drift.dart';
import 'items_table.dart';

@DataClassName('UserActivityEntity')
class UserActivity extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get lastChapterRead => integer().withDefault(const Constant(0))();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();
  RealColumn get progressPercent => real().withDefault(const Constant(0.0))();
  DateTimeColumn get lastReadAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}
