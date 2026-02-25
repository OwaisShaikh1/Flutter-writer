// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapters_dao.dart';

// ignore_for_file: type=lint
mixin _$ChaptersDaoMixin on DatabaseAccessor<AppDatabase> {
  $ItemsTable get items => attachedDatabase.items;
  $ChaptersTable get chapters => attachedDatabase.chapters;
  ChaptersDaoManager get managers => ChaptersDaoManager(this);
}

class ChaptersDaoManager {
  final _$ChaptersDaoMixin _db;
  ChaptersDaoManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db.attachedDatabase, _db.chapters);
}
