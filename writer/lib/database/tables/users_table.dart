import 'package:drift/drift.dart';

@DataClassName('UserEntity')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get username => text().unique()();
  TextColumn get email => text()();
  TextColumn get bio => text().nullable()();
  IntColumn get followers => integer().withDefault(const Constant(0))();
  IntColumn get following => integer().withDefault(const Constant(0))();
  IntColumn get posts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
