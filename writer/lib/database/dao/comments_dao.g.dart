// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_dao.dart';

// ignore_for_file: type=lint
mixin _$CommentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CommentsTable get comments => attachedDatabase.comments;
  CommentsDaoManager get managers => CommentsDaoManager(this);
}

class CommentsDaoManager {
  final _$CommentsDaoMixin _db;
  CommentsDaoManager(this._db);
  $$CommentsTableTableManager get comments =>
      $$CommentsTableTableManager(_db.attachedDatabase, _db.comments);
}
