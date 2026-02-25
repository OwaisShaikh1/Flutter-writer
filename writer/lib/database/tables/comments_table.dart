import 'package:drift/drift.dart';

@DataClassName('CommentEntity')
class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()(); // ID from backend
  IntColumn get itemId => integer()();
  IntColumn get userId => integer()();
  TextColumn get username => text().withDefault(const Constant('Anonymous'))();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
