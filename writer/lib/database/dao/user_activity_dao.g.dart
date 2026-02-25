// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_activity_dao.dart';

// ignore_for_file: type=lint
mixin _$UserActivityDaoMixin on DatabaseAccessor<AppDatabase> {
  $ItemsTable get items => attachedDatabase.items;
  $UserActivityTable get userActivity => attachedDatabase.userActivity;
  UserActivityDaoManager get managers => UserActivityDaoManager(this);
}

class UserActivityDaoManager {
  final _$UserActivityDaoMixin _db;
  UserActivityDaoManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$UserActivityTableTableManager get userActivity =>
      $$UserActivityTableTableManager(_db.attachedDatabase, _db.userActivity);
}
