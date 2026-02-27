// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, UserEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _followersMeta = const VerificationMeta(
    'followers',
  );
  @override
  late final GeneratedColumn<int> followers = GeneratedColumn<int>(
    'followers',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _followingMeta = const VerificationMeta(
    'following',
  );
  @override
  late final GeneratedColumn<int> following = GeneratedColumn<int>(
    'following',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _postsMeta = const VerificationMeta('posts');
  @override
  late final GeneratedColumn<int> posts = GeneratedColumn<int>(
    'posts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    username,
    email,
    bio,
    followers,
    following,
    posts,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('followers')) {
      context.handle(
        _followersMeta,
        followers.isAcceptableOrUnknown(data['followers']!, _followersMeta),
      );
    }
    if (data.containsKey('following')) {
      context.handle(
        _followingMeta,
        following.isAcceptableOrUnknown(data['following']!, _followingMeta),
      );
    }
    if (data.containsKey('posts')) {
      context.handle(
        _postsMeta,
        posts.isAcceptableOrUnknown(data['posts']!, _postsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      followers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}followers'],
      )!,
      following: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}following'],
      )!,
      posts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserEntity extends DataClass implements Insertable<UserEntity> {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? bio;
  final int followers;
  final int following;
  final int posts;
  final DateTime createdAt;
  const UserEntity({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.bio,
    required this.followers,
    required this.following,
    required this.posts,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['username'] = Variable<String>(username);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    map['followers'] = Variable<int>(followers);
    map['following'] = Variable<int>(following);
    map['posts'] = Variable<int>(posts);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      username: Value(username),
      email: Value(email),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      followers: Value(followers),
      following: Value(following),
      posts: Value(posts),
      createdAt: Value(createdAt),
    );
  }

  factory UserEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserEntity(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      username: serializer.fromJson<String>(json['username']),
      email: serializer.fromJson<String>(json['email']),
      bio: serializer.fromJson<String?>(json['bio']),
      followers: serializer.fromJson<int>(json['followers']),
      following: serializer.fromJson<int>(json['following']),
      posts: serializer.fromJson<int>(json['posts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'username': serializer.toJson<String>(username),
      'email': serializer.toJson<String>(email),
      'bio': serializer.toJson<String?>(bio),
      'followers': serializer.toJson<int>(followers),
      'following': serializer.toJson<int>(following),
      'posts': serializer.toJson<int>(posts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserEntity copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    Value<String?> bio = const Value.absent(),
    int? followers,
    int? following,
    int? posts,
    DateTime? createdAt,
  }) => UserEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    username: username ?? this.username,
    email: email ?? this.email,
    bio: bio.present ? bio.value : this.bio,
    followers: followers ?? this.followers,
    following: following ?? this.following,
    posts: posts ?? this.posts,
    createdAt: createdAt ?? this.createdAt,
  );
  UserEntity copyWithCompanion(UsersCompanion data) {
    return UserEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      username: data.username.present ? data.username.value : this.username,
      email: data.email.present ? data.email.value : this.email,
      bio: data.bio.present ? data.bio.value : this.bio,
      followers: data.followers.present ? data.followers.value : this.followers,
      following: data.following.present ? data.following.value : this.following,
      posts: data.posts.present ? data.posts.value : this.posts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('bio: $bio, ')
          ..write('followers: $followers, ')
          ..write('following: $following, ')
          ..write('posts: $posts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    username,
    email,
    bio,
    followers,
    following,
    posts,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.username == this.username &&
          other.email == this.email &&
          other.bio == this.bio &&
          other.followers == this.followers &&
          other.following == this.following &&
          other.posts == this.posts &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<UserEntity> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> username;
  final Value<String> email;
  final Value<String?> bio;
  final Value<int> followers;
  final Value<int> following;
  final Value<int> posts;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.username = const Value.absent(),
    this.email = const Value.absent(),
    this.bio = const Value.absent(),
    this.followers = const Value.absent(),
    this.following = const Value.absent(),
    this.posts = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String username,
    required String email,
    this.bio = const Value.absent(),
    this.followers = const Value.absent(),
    this.following = const Value.absent(),
    this.posts = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       username = Value(username),
       email = Value(email);
  static Insertable<UserEntity> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? username,
    Expression<String>? email,
    Expression<String>? bio,
    Expression<int>? followers,
    Expression<int>? following,
    Expression<int>? posts,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (bio != null) 'bio': bio,
      if (followers != null) 'followers': followers,
      if (following != null) 'following': following,
      if (posts != null) 'posts': posts,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? username,
    Value<String>? email,
    Value<String?>? bio,
    Value<int>? followers,
    Value<int>? following,
    Value<int>? posts,
    Value<DateTime>? createdAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (followers.present) {
      map['followers'] = Variable<int>(followers.value);
    }
    if (following.present) {
      map['following'] = Variable<int>(following.value);
    }
    if (posts.present) {
      map['posts'] = Variable<int>(posts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('bio: $bio, ')
          ..write('followers: $followers, ')
          ..write('following: $following, ')
          ..write('posts: $posts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<int> authorId = GeneratedColumn<int>(
    'author_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _chaptersCountMeta = const VerificationMeta(
    'chaptersCount',
  );
  @override
  late final GeneratedColumn<int> chaptersCount = GeneratedColumn<int>(
    'chapters_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _commentsCountMeta = const VerificationMeta(
    'commentsCount',
  );
  @override
  late final GeneratedColumn<int> commentsCount = GeneratedColumn<int>(
    'comments_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _likesCountMeta = const VerificationMeta(
    'likesCount',
  );
  @override
  late final GeneratedColumn<int> likesCount = GeneratedColumn<int>(
    'likes_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isLikedByUserMeta = const VerificationMeta(
    'isLikedByUser',
  );
  @override
  late final GeneratedColumn<bool> isLikedByUser = GeneratedColumn<bool>(
    'is_liked_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_liked_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageLocalPathMeta = const VerificationMeta(
    'imageLocalPath',
  );
  @override
  late final GeneratedColumn<String> imageLocalPath = GeneratedColumn<String>(
    'image_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    author,
    authorId,
    type,
    rating,
    chaptersCount,
    commentsCount,
    likesCount,
    isLikedByUser,
    imageUrl,
    imageLocalPath,
    description,
    isFavorite,
    isSynced,
    lastSyncedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('chapters_count')) {
      context.handle(
        _chaptersCountMeta,
        chaptersCount.isAcceptableOrUnknown(
          data['chapters_count']!,
          _chaptersCountMeta,
        ),
      );
    }
    if (data.containsKey('comments_count')) {
      context.handle(
        _commentsCountMeta,
        commentsCount.isAcceptableOrUnknown(
          data['comments_count']!,
          _commentsCountMeta,
        ),
      );
    }
    if (data.containsKey('likes_count')) {
      context.handle(
        _likesCountMeta,
        likesCount.isAcceptableOrUnknown(data['likes_count']!, _likesCountMeta),
      );
    }
    if (data.containsKey('is_liked_by_user')) {
      context.handle(
        _isLikedByUserMeta,
        isLikedByUser.isAcceptableOrUnknown(
          data['is_liked_by_user']!,
          _isLikedByUserMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('image_local_path')) {
      context.handle(
        _imageLocalPathMeta,
        imageLocalPath.isAcceptableOrUnknown(
          data['image_local_path']!,
          _imageLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}author_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      chaptersCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapters_count'],
      )!,
      commentsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}comments_count'],
      )!,
      likesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}likes_count'],
      )!,
      isLikedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_liked_by_user'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      imageLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_local_path'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class ItemEntity extends DataClass implements Insertable<ItemEntity> {
  final int id;
  final int? serverId;
  final String name;
  final String author;
  final int? authorId;
  final String type;
  final double rating;
  final int chaptersCount;
  final int commentsCount;
  final int likesCount;
  final bool isLikedByUser;
  final String? imageUrl;
  final String? imageLocalPath;
  final String description;
  final bool isFavorite;
  final bool isSynced;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  const ItemEntity({
    required this.id,
    this.serverId,
    required this.name,
    required this.author,
    this.authorId,
    required this.type,
    required this.rating,
    required this.chaptersCount,
    required this.commentsCount,
    required this.likesCount,
    required this.isLikedByUser,
    this.imageUrl,
    this.imageLocalPath,
    required this.description,
    required this.isFavorite,
    required this.isSynced,
    this.lastSyncedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['name'] = Variable<String>(name);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || authorId != null) {
      map['author_id'] = Variable<int>(authorId);
    }
    map['type'] = Variable<String>(type);
    map['rating'] = Variable<double>(rating);
    map['chapters_count'] = Variable<int>(chaptersCount);
    map['comments_count'] = Variable<int>(commentsCount);
    map['likes_count'] = Variable<int>(likesCount);
    map['is_liked_by_user'] = Variable<bool>(isLikedByUser);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || imageLocalPath != null) {
      map['image_local_path'] = Variable<String>(imageLocalPath);
    }
    map['description'] = Variable<String>(description);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      author: Value(author),
      authorId: authorId == null && nullToAbsent
          ? const Value.absent()
          : Value(authorId),
      type: Value(type),
      rating: Value(rating),
      chaptersCount: Value(chaptersCount),
      commentsCount: Value(commentsCount),
      likesCount: Value(likesCount),
      isLikedByUser: Value(isLikedByUser),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      imageLocalPath: imageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(imageLocalPath),
      description: Value(description),
      isFavorite: Value(isFavorite),
      isSynced: Value(isSynced),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
    );
  }

  factory ItemEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemEntity(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      author: serializer.fromJson<String>(json['author']),
      authorId: serializer.fromJson<int?>(json['authorId']),
      type: serializer.fromJson<String>(json['type']),
      rating: serializer.fromJson<double>(json['rating']),
      chaptersCount: serializer.fromJson<int>(json['chaptersCount']),
      commentsCount: serializer.fromJson<int>(json['commentsCount']),
      likesCount: serializer.fromJson<int>(json['likesCount']),
      isLikedByUser: serializer.fromJson<bool>(json['isLikedByUser']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      imageLocalPath: serializer.fromJson<String?>(json['imageLocalPath']),
      description: serializer.fromJson<String>(json['description']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'name': serializer.toJson<String>(name),
      'author': serializer.toJson<String>(author),
      'authorId': serializer.toJson<int?>(authorId),
      'type': serializer.toJson<String>(type),
      'rating': serializer.toJson<double>(rating),
      'chaptersCount': serializer.toJson<int>(chaptersCount),
      'commentsCount': serializer.toJson<int>(commentsCount),
      'likesCount': serializer.toJson<int>(likesCount),
      'isLikedByUser': serializer.toJson<bool>(isLikedByUser),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'imageLocalPath': serializer.toJson<String?>(imageLocalPath),
      'description': serializer.toJson<String>(description),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ItemEntity copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    String? name,
    String? author,
    Value<int?> authorId = const Value.absent(),
    String? type,
    double? rating,
    int? chaptersCount,
    int? commentsCount,
    int? likesCount,
    bool? isLikedByUser,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> imageLocalPath = const Value.absent(),
    String? description,
    bool? isFavorite,
    bool? isSynced,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    DateTime? createdAt,
  }) => ItemEntity(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    name: name ?? this.name,
    author: author ?? this.author,
    authorId: authorId.present ? authorId.value : this.authorId,
    type: type ?? this.type,
    rating: rating ?? this.rating,
    chaptersCount: chaptersCount ?? this.chaptersCount,
    commentsCount: commentsCount ?? this.commentsCount,
    likesCount: likesCount ?? this.likesCount,
    isLikedByUser: isLikedByUser ?? this.isLikedByUser,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    imageLocalPath: imageLocalPath.present
        ? imageLocalPath.value
        : this.imageLocalPath,
    description: description ?? this.description,
    isFavorite: isFavorite ?? this.isFavorite,
    isSynced: isSynced ?? this.isSynced,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  ItemEntity copyWithCompanion(ItemsCompanion data) {
    return ItemEntity(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      author: data.author.present ? data.author.value : this.author,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      type: data.type.present ? data.type.value : this.type,
      rating: data.rating.present ? data.rating.value : this.rating,
      chaptersCount: data.chaptersCount.present
          ? data.chaptersCount.value
          : this.chaptersCount,
      commentsCount: data.commentsCount.present
          ? data.commentsCount.value
          : this.commentsCount,
      likesCount: data.likesCount.present
          ? data.likesCount.value
          : this.likesCount,
      isLikedByUser: data.isLikedByUser.present
          ? data.isLikedByUser.value
          : this.isLikedByUser,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      imageLocalPath: data.imageLocalPath.present
          ? data.imageLocalPath.value
          : this.imageLocalPath,
      description: data.description.present
          ? data.description.value
          : this.description,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemEntity(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('authorId: $authorId, ')
          ..write('type: $type, ')
          ..write('rating: $rating, ')
          ..write('chaptersCount: $chaptersCount, ')
          ..write('commentsCount: $commentsCount, ')
          ..write('likesCount: $likesCount, ')
          ..write('isLikedByUser: $isLikedByUser, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('description: $description, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    name,
    author,
    authorId,
    type,
    rating,
    chaptersCount,
    commentsCount,
    likesCount,
    isLikedByUser,
    imageUrl,
    imageLocalPath,
    description,
    isFavorite,
    isSynced,
    lastSyncedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemEntity &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.author == this.author &&
          other.authorId == this.authorId &&
          other.type == this.type &&
          other.rating == this.rating &&
          other.chaptersCount == this.chaptersCount &&
          other.commentsCount == this.commentsCount &&
          other.likesCount == this.likesCount &&
          other.isLikedByUser == this.isLikedByUser &&
          other.imageUrl == this.imageUrl &&
          other.imageLocalPath == this.imageLocalPath &&
          other.description == this.description &&
          other.isFavorite == this.isFavorite &&
          other.isSynced == this.isSynced &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt);
}

class ItemsCompanion extends UpdateCompanion<ItemEntity> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> name;
  final Value<String> author;
  final Value<int?> authorId;
  final Value<String> type;
  final Value<double> rating;
  final Value<int> chaptersCount;
  final Value<int> commentsCount;
  final Value<int> likesCount;
  final Value<bool> isLikedByUser;
  final Value<String?> imageUrl;
  final Value<String?> imageLocalPath;
  final Value<String> description;
  final Value<bool> isFavorite;
  final Value<bool> isSynced;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> createdAt;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.author = const Value.absent(),
    this.authorId = const Value.absent(),
    this.type = const Value.absent(),
    this.rating = const Value.absent(),
    this.chaptersCount = const Value.absent(),
    this.commentsCount = const Value.absent(),
    this.likesCount = const Value.absent(),
    this.isLikedByUser = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.imageLocalPath = const Value.absent(),
    this.description = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    required String author,
    this.authorId = const Value.absent(),
    required String type,
    this.rating = const Value.absent(),
    this.chaptersCount = const Value.absent(),
    this.commentsCount = const Value.absent(),
    this.likesCount = const Value.absent(),
    this.isLikedByUser = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.imageLocalPath = const Value.absent(),
    required String description,
    this.isFavorite = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       author = Value(author),
       type = Value(type),
       description = Value(description);
  static Insertable<ItemEntity> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? author,
    Expression<int>? authorId,
    Expression<String>? type,
    Expression<double>? rating,
    Expression<int>? chaptersCount,
    Expression<int>? commentsCount,
    Expression<int>? likesCount,
    Expression<bool>? isLikedByUser,
    Expression<String>? imageUrl,
    Expression<String>? imageLocalPath,
    Expression<String>? description,
    Expression<bool>? isFavorite,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (author != null) 'author': author,
      if (authorId != null) 'author_id': authorId,
      if (type != null) 'type': type,
      if (rating != null) 'rating': rating,
      if (chaptersCount != null) 'chapters_count': chaptersCount,
      if (commentsCount != null) 'comments_count': commentsCount,
      if (likesCount != null) 'likes_count': likesCount,
      if (isLikedByUser != null) 'is_liked_by_user': isLikedByUser,
      if (imageUrl != null) 'image_url': imageUrl,
      if (imageLocalPath != null) 'image_local_path': imageLocalPath,
      if (description != null) 'description': description,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String>? name,
    Value<String>? author,
    Value<int?>? authorId,
    Value<String>? type,
    Value<double>? rating,
    Value<int>? chaptersCount,
    Value<int>? commentsCount,
    Value<int>? likesCount,
    Value<bool>? isLikedByUser,
    Value<String?>? imageUrl,
    Value<String?>? imageLocalPath,
    Value<String>? description,
    Value<bool>? isFavorite,
    Value<bool>? isSynced,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime>? createdAt,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      chaptersCount: chaptersCount ?? this.chaptersCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      imageUrl: imageUrl ?? this.imageUrl,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<int>(authorId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (chaptersCount.present) {
      map['chapters_count'] = Variable<int>(chaptersCount.value);
    }
    if (commentsCount.present) {
      map['comments_count'] = Variable<int>(commentsCount.value);
    }
    if (likesCount.present) {
      map['likes_count'] = Variable<int>(likesCount.value);
    }
    if (isLikedByUser.present) {
      map['is_liked_by_user'] = Variable<bool>(isLikedByUser.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (imageLocalPath.present) {
      map['image_local_path'] = Variable<String>(imageLocalPath.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('authorId: $authorId, ')
          ..write('type: $type, ')
          ..write('rating: $rating, ')
          ..write('chaptersCount: $chaptersCount, ')
          ..write('commentsCount: $commentsCount, ')
          ..write('likesCount: $likesCount, ')
          ..write('isLikedByUser: $isLikedByUser, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('description: $description, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters
    with TableInfo<$ChaptersTable, ChapterEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDownloadedMeta = const VerificationMeta(
    'isDownloaded',
  );
  @override
  late final GeneratedColumn<bool> isDownloaded = GeneratedColumn<bool>(
    'is_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_downloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    number,
    title,
    content,
    isDownloaded,
    downloadedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_downloaded')) {
      context.handle(
        _isDownloadedMeta,
        isDownloaded.isAcceptableOrUnknown(
          data['is_downloaded']!,
          _isDownloadedMeta,
        ),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemId, number},
  ];
  @override
  ChapterEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      isDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_downloaded'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class ChapterEntity extends DataClass implements Insertable<ChapterEntity> {
  final int id;
  final int itemId;
  final int number;
  final String title;
  final String content;
  final bool isDownloaded;
  final DateTime? downloadedAt;
  final DateTime createdAt;
  const ChapterEntity({
    required this.id,
    required this.itemId,
    required this.number,
    required this.title,
    required this.content,
    required this.isDownloaded,
    this.downloadedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['number'] = Variable<int>(number);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['is_downloaded'] = Variable<bool>(isDownloaded);
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      itemId: Value(itemId),
      number: Value(number),
      title: Value(title),
      content: Value(content),
      isDownloaded: Value(isDownloaded),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
      createdAt: Value(createdAt),
    );
  }

  factory ChapterEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterEntity(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      number: serializer.fromJson<int>(json['number']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      isDownloaded: serializer.fromJson<bool>(json['isDownloaded']),
      downloadedAt: serializer.fromJson<DateTime?>(json['downloadedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'number': serializer.toJson<int>(number),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'isDownloaded': serializer.toJson<bool>(isDownloaded),
      'downloadedAt': serializer.toJson<DateTime?>(downloadedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChapterEntity copyWith({
    int? id,
    int? itemId,
    int? number,
    String? title,
    String? content,
    bool? isDownloaded,
    Value<DateTime?> downloadedAt = const Value.absent(),
    DateTime? createdAt,
  }) => ChapterEntity(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    number: number ?? this.number,
    title: title ?? this.title,
    content: content ?? this.content,
    isDownloaded: isDownloaded ?? this.isDownloaded,
    downloadedAt: downloadedAt.present ? downloadedAt.value : this.downloadedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  ChapterEntity copyWithCompanion(ChaptersCompanion data) {
    return ChapterEntity(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      number: data.number.present ? data.number.value : this.number,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      isDownloaded: data.isDownloaded.present
          ? data.isDownloaded.value
          : this.isDownloaded,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterEntity(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    number,
    title,
    content,
    isDownloaded,
    downloadedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterEntity &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.number == this.number &&
          other.title == this.title &&
          other.content == this.content &&
          other.isDownloaded == this.isDownloaded &&
          other.downloadedAt == this.downloadedAt &&
          other.createdAt == this.createdAt);
}

class ChaptersCompanion extends UpdateCompanion<ChapterEntity> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<int> number;
  final Value<String> title;
  final Value<String> content;
  final Value<bool> isDownloaded;
  final Value<DateTime?> downloadedAt;
  final Value<DateTime> createdAt;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChaptersCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required int number,
    required String title,
    required String content,
    this.isDownloaded = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : itemId = Value(itemId),
       number = Value(number),
       title = Value(title),
       content = Value(content);
  static Insertable<ChapterEntity> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<int>? number,
    Expression<String>? title,
    Expression<String>? content,
    Expression<bool>? isDownloaded,
    Expression<DateTime>? downloadedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (number != null) 'number': number,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (isDownloaded != null) 'is_downloaded': isDownloaded,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChaptersCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<int>? number,
    Value<String>? title,
    Value<String>? content,
    Value<bool>? isDownloaded,
    Value<DateTime?>? downloadedAt,
    Value<DateTime>? createdAt,
  }) {
    return ChaptersCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      number: number ?? this.number,
      title: title ?? this.title,
      content: content ?? this.content,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isDownloaded.present) {
      map['is_downloaded'] = Variable<bool>(isDownloaded.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UserActivityTable extends UserActivity
    with TableInfo<$UserActivityTable, UserActivityEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserActivityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _lastChapterReadMeta = const VerificationMeta(
    'lastChapterRead',
  );
  @override
  late final GeneratedColumn<int> lastChapterRead = GeneratedColumn<int>(
    'last_chapter_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentPageMeta = const VerificationMeta(
    'currentPage',
  );
  @override
  late final GeneratedColumn<int> currentPage = GeneratedColumn<int>(
    'current_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressPercentMeta = const VerificationMeta(
    'progressPercent',
  );
  @override
  late final GeneratedColumn<double> progressPercent = GeneratedColumn<double>(
    'progress_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
    'last_read_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    lastChapterRead,
    currentPage,
    progressPercent,
    lastReadAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_activity';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserActivityEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('last_chapter_read')) {
      context.handle(
        _lastChapterReadMeta,
        lastChapterRead.isAcceptableOrUnknown(
          data['last_chapter_read']!,
          _lastChapterReadMeta,
        ),
      );
    }
    if (data.containsKey('current_page')) {
      context.handle(
        _currentPageMeta,
        currentPage.isAcceptableOrUnknown(
          data['current_page']!,
          _currentPageMeta,
        ),
      );
    }
    if (data.containsKey('progress_percent')) {
      context.handle(
        _progressPercentMeta,
        progressPercent.isAcceptableOrUnknown(
          data['progress_percent']!,
          _progressPercentMeta,
        ),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserActivityEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserActivityEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      lastChapterRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_chapter_read'],
      )!,
      currentPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_page'],
      )!,
      progressPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_percent'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $UserActivityTable createAlias(String alias) {
    return $UserActivityTable(attachedDatabase, alias);
  }
}

class UserActivityEntity extends DataClass
    implements Insertable<UserActivityEntity> {
  final int id;
  final int itemId;
  final int lastChapterRead;
  final int currentPage;
  final double progressPercent;
  final DateTime lastReadAt;
  final String? notes;
  const UserActivityEntity({
    required this.id,
    required this.itemId,
    required this.lastChapterRead,
    required this.currentPage,
    required this.progressPercent,
    required this.lastReadAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['last_chapter_read'] = Variable<int>(lastChapterRead);
    map['current_page'] = Variable<int>(currentPage);
    map['progress_percent'] = Variable<double>(progressPercent);
    map['last_read_at'] = Variable<DateTime>(lastReadAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  UserActivityCompanion toCompanion(bool nullToAbsent) {
    return UserActivityCompanion(
      id: Value(id),
      itemId: Value(itemId),
      lastChapterRead: Value(lastChapterRead),
      currentPage: Value(currentPage),
      progressPercent: Value(progressPercent),
      lastReadAt: Value(lastReadAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory UserActivityEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserActivityEntity(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      lastChapterRead: serializer.fromJson<int>(json['lastChapterRead']),
      currentPage: serializer.fromJson<int>(json['currentPage']),
      progressPercent: serializer.fromJson<double>(json['progressPercent']),
      lastReadAt: serializer.fromJson<DateTime>(json['lastReadAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'lastChapterRead': serializer.toJson<int>(lastChapterRead),
      'currentPage': serializer.toJson<int>(currentPage),
      'progressPercent': serializer.toJson<double>(progressPercent),
      'lastReadAt': serializer.toJson<DateTime>(lastReadAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  UserActivityEntity copyWith({
    int? id,
    int? itemId,
    int? lastChapterRead,
    int? currentPage,
    double? progressPercent,
    DateTime? lastReadAt,
    Value<String?> notes = const Value.absent(),
  }) => UserActivityEntity(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    lastChapterRead: lastChapterRead ?? this.lastChapterRead,
    currentPage: currentPage ?? this.currentPage,
    progressPercent: progressPercent ?? this.progressPercent,
    lastReadAt: lastReadAt ?? this.lastReadAt,
    notes: notes.present ? notes.value : this.notes,
  );
  UserActivityEntity copyWithCompanion(UserActivityCompanion data) {
    return UserActivityEntity(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      lastChapterRead: data.lastChapterRead.present
          ? data.lastChapterRead.value
          : this.lastChapterRead,
      currentPage: data.currentPage.present
          ? data.currentPage.value
          : this.currentPage,
      progressPercent: data.progressPercent.present
          ? data.progressPercent.value
          : this.progressPercent,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserActivityEntity(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('lastChapterRead: $lastChapterRead, ')
          ..write('currentPage: $currentPage, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    lastChapterRead,
    currentPage,
    progressPercent,
    lastReadAt,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserActivityEntity &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.lastChapterRead == this.lastChapterRead &&
          other.currentPage == this.currentPage &&
          other.progressPercent == this.progressPercent &&
          other.lastReadAt == this.lastReadAt &&
          other.notes == this.notes);
}

class UserActivityCompanion extends UpdateCompanion<UserActivityEntity> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<int> lastChapterRead;
  final Value<int> currentPage;
  final Value<double> progressPercent;
  final Value<DateTime> lastReadAt;
  final Value<String?> notes;
  const UserActivityCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.lastChapterRead = const Value.absent(),
    this.currentPage = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  UserActivityCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    this.lastChapterRead = const Value.absent(),
    this.currentPage = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.notes = const Value.absent(),
  }) : itemId = Value(itemId);
  static Insertable<UserActivityEntity> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<int>? lastChapterRead,
    Expression<int>? currentPage,
    Expression<double>? progressPercent,
    Expression<DateTime>? lastReadAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (lastChapterRead != null) 'last_chapter_read': lastChapterRead,
      if (currentPage != null) 'current_page': currentPage,
      if (progressPercent != null) 'progress_percent': progressPercent,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (notes != null) 'notes': notes,
    });
  }

  UserActivityCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<int>? lastChapterRead,
    Value<int>? currentPage,
    Value<double>? progressPercent,
    Value<DateTime>? lastReadAt,
    Value<String?>? notes,
  }) {
    return UserActivityCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      lastChapterRead: lastChapterRead ?? this.lastChapterRead,
      currentPage: currentPage ?? this.currentPage,
      progressPercent: progressPercent ?? this.progressPercent,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (lastChapterRead.present) {
      map['last_chapter_read'] = Variable<int>(lastChapterRead.value);
    }
    if (currentPage.present) {
      map['current_page'] = Variable<int>(currentPage.value);
    }
    if (progressPercent.present) {
      map['progress_percent'] = Variable<double>(progressPercent.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserActivityCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('lastChapterRead: $lastChapterRead, ')
          ..write('currentPage: $currentPage, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SyncLogTable extends SyncLog
    with TableInfo<$SyncLogTable, SyncLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    entityType,
    entityId,
    parentId,
    operation,
    payload,
    createdAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entity_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncLogTable createAlias(String alias) {
    return $SyncLogTable(attachedDatabase, alias);
  }
}

class SyncLogEntry extends DataClass implements Insertable<SyncLogEntry> {
  final int id;

  /// The user ID who made this change (for multi-user support)
  final int? userId;

  /// Type of entity: 'item' or 'chapter'
  final String entityType;

  /// The ID of the entity (local ID for new items, backend ID for existing)
  final int entityId;

  /// For chapters: the parent item ID
  final int? parentId;

  /// Operation type: 'create', 'update', 'delete'
  final String operation;

  /// JSON payload with the data to sync
  final String payload;

  /// When this change was made
  final DateTime createdAt;

  /// Number of sync attempts (for retry logic)
  final int attempts;

  /// Last error message if sync failed
  final String? lastError;
  const SyncLogEntry({
    required this.id,
    this.userId,
    required this.entityType,
    required this.entityId,
    this.parentId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<int>(entityId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncLogCompanion toCompanion(bool nullToAbsent) {
    return SyncLogCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      operation: Value(operation),
      payload: Value(payload),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogEntry(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int?>(json['userId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int?>(userId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<int>(entityId),
      'parentId': serializer.toJson<int?>(parentId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncLogEntry copyWith({
    int? id,
    Value<int?> userId = const Value.absent(),
    String? entityType,
    int? entityId,
    Value<int?> parentId = const Value.absent(),
    String? operation,
    String? payload,
    DateTime? createdAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => SyncLogEntry(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    parentId: parentId.present ? parentId.value : this.parentId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncLogEntry copyWithCompanion(SyncLogCompanion data) {
    return SyncLogEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('parentId: $parentId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    entityType,
    entityId,
    parentId,
    operation,
    payload,
    createdAt,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.parentId == this.parentId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class SyncLogCompanion extends UpdateCompanion<SyncLogEntry> {
  final Value<int> id;
  final Value<int?> userId;
  final Value<String> entityType;
  final Value<int> entityId;
  final Value<int?> parentId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  const SyncLogCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncLogCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    required String entityType,
    required int entityId,
    this.parentId = const Value.absent(),
    required String operation,
    required String payload,
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payload = Value(payload);
  static Insertable<SyncLogEntry> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? entityType,
    Expression<int>? entityId,
    Expression<int>? parentId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (parentId != null) 'parent_id': parentId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncLogCompanion copyWith({
    Value<int>? id,
    Value<int?>? userId,
    Value<String>? entityType,
    Value<int>? entityId,
    Value<int?>? parentId,
    Value<String>? operation,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<String?>? lastError,
  }) {
    return SyncLogCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      parentId: parentId ?? this.parentId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('parentId: $parentId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $CommentsTable extends Comments
    with TableInfo<$CommentsTable, CommentEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Anonymous'),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    itemId,
    userId,
    username,
    content,
    createdAt,
    updatedAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommentEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommentEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommentEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $CommentsTable createAlias(String alias) {
    return $CommentsTable(attachedDatabase, alias);
  }
}

class CommentEntity extends DataClass implements Insertable<CommentEntity> {
  final int id;
  final int? remoteId;
  final int itemId;
  final int userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  const CommentEntity({
    required this.id,
    this.remoteId,
    required this.itemId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['item_id'] = Variable<int>(itemId);
    map['user_id'] = Variable<int>(userId);
    map['username'] = Variable<String>(username);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  CommentsCompanion toCompanion(bool nullToAbsent) {
    return CommentsCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      itemId: Value(itemId),
      userId: Value(userId),
      username: Value(username),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isSynced: Value(isSynced),
    );
  }

  factory CommentEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommentEntity(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      itemId: serializer.fromJson<int>(json['itemId']),
      userId: serializer.fromJson<int>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<int?>(remoteId),
      'itemId': serializer.toJson<int>(itemId),
      'userId': serializer.toJson<int>(userId),
      'username': serializer.toJson<String>(username),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  CommentEntity copyWith({
    int? id,
    Value<int?> remoteId = const Value.absent(),
    int? itemId,
    int? userId,
    String? username,
    String? content,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isSynced,
  }) => CommentEntity(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    itemId: itemId ?? this.itemId,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
  );
  CommentEntity copyWithCompanion(CommentsCompanion data) {
    return CommentEntity(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommentEntity(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    itemId,
    userId,
    username,
    content,
    createdAt,
    updatedAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommentEntity &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.itemId == this.itemId &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced);
}

class CommentsCompanion extends UpdateCompanion<CommentEntity> {
  final Value<int> id;
  final Value<int?> remoteId;
  final Value<int> itemId;
  final Value<int> userId;
  final Value<String> username;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isSynced;
  const CommentsCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  CommentsCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required int itemId,
    required int userId,
    this.username = const Value.absent(),
    required String content,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
  }) : itemId = Value(itemId),
       userId = Value(userId),
       content = Value(content);
  static Insertable<CommentEntity> custom({
    Expression<int>? id,
    Expression<int>? remoteId,
    Expression<int>? itemId,
    Expression<int>? userId,
    Expression<String>? username,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (itemId != null) 'item_id': itemId,
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  CommentsCompanion copyWith({
    Value<int>? id,
    Value<int?>? remoteId,
    Value<int>? itemId,
    Value<int>? userId,
    Value<String>? username,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<bool>? isSynced,
  }) {
    return CommentsCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommentsCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $UserActivityTable userActivity = $UserActivityTable(this);
  late final $SyncLogTable syncLog = $SyncLogTable(this);
  late final $CommentsTable comments = $CommentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    items,
    chapters,
    userActivity,
    syncLog,
    comments,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_activity', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String name,
      required String username,
      required String email,
      Value<String?> bio,
      Value<int> followers,
      Value<int> following,
      Value<int> posts,
      Value<DateTime> createdAt,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> username,
      Value<String> email,
      Value<String?> bio,
      Value<int> followers,
      Value<int> following,
      Value<int> posts,
      Value<DateTime> createdAt,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get followers => $composableBuilder(
    column: $table.followers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get following => $composableBuilder(
    column: $table.following,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get posts => $composableBuilder(
    column: $table.posts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get followers => $composableBuilder(
    column: $table.followers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get following => $composableBuilder(
    column: $table.following,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get posts => $composableBuilder(
    column: $table.posts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<int> get followers =>
      $composableBuilder(column: $table.followers, builder: (column) => column);

  GeneratedColumn<int> get following =>
      $composableBuilder(column: $table.following, builder: (column) => column);

  GeneratedColumn<int> get posts =>
      $composableBuilder(column: $table.posts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          UserEntity,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserEntity, BaseReferences<_$AppDatabase, $UsersTable, UserEntity>),
          UserEntity,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<int> followers = const Value.absent(),
                Value<int> following = const Value.absent(),
                Value<int> posts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                username: username,
                email: email,
                bio: bio,
                followers: followers,
                following: following,
                posts: posts,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String username,
                required String email,
                Value<String?> bio = const Value.absent(),
                Value<int> followers = const Value.absent(),
                Value<int> following = const Value.absent(),
                Value<int> posts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                username: username,
                email: email,
                bio: bio,
                followers: followers,
                following: following,
                posts: posts,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      UserEntity,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserEntity, BaseReferences<_$AppDatabase, $UsersTable, UserEntity>),
      UserEntity,
      PrefetchHooks Function()
    >;
typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required String name,
      required String author,
      Value<int?> authorId,
      required String type,
      Value<double> rating,
      Value<int> chaptersCount,
      Value<int> commentsCount,
      Value<int> likesCount,
      Value<bool> isLikedByUser,
      Value<String?> imageUrl,
      Value<String?> imageLocalPath,
      required String description,
      Value<bool> isFavorite,
      Value<bool> isSynced,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime> createdAt,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String> name,
      Value<String> author,
      Value<int?> authorId,
      Value<String> type,
      Value<double> rating,
      Value<int> chaptersCount,
      Value<int> commentsCount,
      Value<int> likesCount,
      Value<bool> isLikedByUser,
      Value<String?> imageUrl,
      Value<String?> imageLocalPath,
      Value<String> description,
      Value<bool> isFavorite,
      Value<bool> isSynced,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime> createdAt,
    });

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, ItemEntity> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChaptersTable, List<ChapterEntity>>
  _chaptersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: $_aliasNameGenerator(db.items.id, db.chapters.itemId),
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserActivityTable, List<UserActivityEntity>>
  _userActivityRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userActivity,
    aliasName: $_aliasNameGenerator(db.items.id, db.userActivity.itemId),
  );

  $$UserActivityTableProcessedTableManager get userActivityRefs {
    final manager = $$UserActivityTableTableManager(
      $_db,
      $_db.userActivity,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userActivityRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chaptersCount => $composableBuilder(
    column: $table.chaptersCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get commentsCount => $composableBuilder(
    column: $table.commentsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get likesCount => $composableBuilder(
    column: $table.likesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLikedByUser => $composableBuilder(
    column: $table.isLikedByUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageLocalPath => $composableBuilder(
    column: $table.imageLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userActivityRefs(
    Expression<bool> Function($$UserActivityTableFilterComposer f) f,
  ) {
    final $$UserActivityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userActivity,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserActivityTableFilterComposer(
            $db: $db,
            $table: $db.userActivity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chaptersCount => $composableBuilder(
    column: $table.chaptersCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get commentsCount => $composableBuilder(
    column: $table.commentsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get likesCount => $composableBuilder(
    column: $table.likesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLikedByUser => $composableBuilder(
    column: $table.isLikedByUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageLocalPath => $composableBuilder(
    column: $table.imageLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<int> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get chaptersCount => $composableBuilder(
    column: $table.chaptersCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get commentsCount => $composableBuilder(
    column: $table.commentsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get likesCount => $composableBuilder(
    column: $table.likesCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLikedByUser => $composableBuilder(
    column: $table.isLikedByUser,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get imageLocalPath => $composableBuilder(
    column: $table.imageLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userActivityRefs<T extends Object>(
    Expression<T> Function($$UserActivityTableAnnotationComposer a) f,
  ) {
    final $$UserActivityTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userActivity,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserActivityTableAnnotationComposer(
            $db: $db,
            $table: $db.userActivity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          ItemEntity,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (ItemEntity, $$ItemsTableReferences),
          ItemEntity,
          PrefetchHooks Function({bool chaptersRefs, bool userActivityRefs})
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<int?> authorId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> chaptersCount = const Value.absent(),
                Value<int> commentsCount = const Value.absent(),
                Value<int> likesCount = const Value.absent(),
                Value<bool> isLikedByUser = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> imageLocalPath = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                serverId: serverId,
                name: name,
                author: author,
                authorId: authorId,
                type: type,
                rating: rating,
                chaptersCount: chaptersCount,
                commentsCount: commentsCount,
                likesCount: likesCount,
                isLikedByUser: isLikedByUser,
                imageUrl: imageUrl,
                imageLocalPath: imageLocalPath,
                description: description,
                isFavorite: isFavorite,
                isSynced: isSynced,
                lastSyncedAt: lastSyncedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String name,
                required String author,
                Value<int?> authorId = const Value.absent(),
                required String type,
                Value<double> rating = const Value.absent(),
                Value<int> chaptersCount = const Value.absent(),
                Value<int> commentsCount = const Value.absent(),
                Value<int> likesCount = const Value.absent(),
                Value<bool> isLikedByUser = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> imageLocalPath = const Value.absent(),
                required String description,
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                author: author,
                authorId: authorId,
                type: type,
                rating: rating,
                chaptersCount: chaptersCount,
                commentsCount: commentsCount,
                likesCount: likesCount,
                isLikedByUser: isLikedByUser,
                imageUrl: imageUrl,
                imageLocalPath: imageLocalPath,
                description: description,
                isFavorite: isFavorite,
                isSynced: isSynced,
                lastSyncedAt: lastSyncedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ItemsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({chaptersRefs = false, userActivityRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (chaptersRefs) db.chapters,
                    if (userActivityRefs) db.userActivity,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (chaptersRefs)
                        await $_getPrefetchedData<
                          ItemEntity,
                          $ItemsTable,
                          ChapterEntity
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userActivityRefs)
                        await $_getPrefetchedData<
                          ItemEntity,
                          $ItemsTable,
                          UserActivityEntity
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._userActivityRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).userActivityRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      ItemEntity,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (ItemEntity, $$ItemsTableReferences),
      ItemEntity,
      PrefetchHooks Function({bool chaptersRefs, bool userActivityRefs})
    >;
typedef $$ChaptersTableCreateCompanionBuilder =
    ChaptersCompanion Function({
      Value<int> id,
      required int itemId,
      required int number,
      required String title,
      required String content,
      Value<bool> isDownloaded,
      Value<DateTime?> downloadedAt,
      Value<DateTime> createdAt,
    });
typedef $$ChaptersTableUpdateCompanionBuilder =
    ChaptersCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<int> number,
      Value<String> title,
      Value<String> content,
      Value<bool> isDownloaded,
      Value<DateTime?> downloadedAt,
      Value<DateTime> createdAt,
    });

final class $$ChaptersTableReferences
    extends BaseReferences<_$AppDatabase, $ChaptersTable, ChapterEntity> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.chapters.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChaptersTable,
          ChapterEntity,
          $$ChaptersTableFilterComposer,
          $$ChaptersTableOrderingComposer,
          $$ChaptersTableAnnotationComposer,
          $$ChaptersTableCreateCompanionBuilder,
          $$ChaptersTableUpdateCompanionBuilder,
          (ChapterEntity, $$ChaptersTableReferences),
          ChapterEntity,
          PrefetchHooks Function({bool itemId})
        > {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChaptersCompanion(
                id: id,
                itemId: itemId,
                number: number,
                title: title,
                content: content,
                isDownloaded: isDownloaded,
                downloadedAt: downloadedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required int number,
                required String title,
                required String content,
                Value<bool> isDownloaded = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChaptersCompanion.insert(
                id: id,
                itemId: itemId,
                number: number,
                title: title,
                content: content,
                isDownloaded: isDownloaded,
                downloadedAt: downloadedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$ChaptersTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$ChaptersTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChaptersTable,
      ChapterEntity,
      $$ChaptersTableFilterComposer,
      $$ChaptersTableOrderingComposer,
      $$ChaptersTableAnnotationComposer,
      $$ChaptersTableCreateCompanionBuilder,
      $$ChaptersTableUpdateCompanionBuilder,
      (ChapterEntity, $$ChaptersTableReferences),
      ChapterEntity,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$UserActivityTableCreateCompanionBuilder =
    UserActivityCompanion Function({
      Value<int> id,
      required int itemId,
      Value<int> lastChapterRead,
      Value<int> currentPage,
      Value<double> progressPercent,
      Value<DateTime> lastReadAt,
      Value<String?> notes,
    });
typedef $$UserActivityTableUpdateCompanionBuilder =
    UserActivityCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<int> lastChapterRead,
      Value<int> currentPage,
      Value<double> progressPercent,
      Value<DateTime> lastReadAt,
      Value<String?> notes,
    });

final class $$UserActivityTableReferences
    extends
        BaseReferences<_$AppDatabase, $UserActivityTable, UserActivityEntity> {
  $$UserActivityTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.userActivity.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserActivityTableFilterComposer
    extends Composer<_$AppDatabase, $UserActivityTable> {
  $$UserActivityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastChapterRead => $composableBuilder(
    column: $table.lastChapterRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserActivityTableOrderingComposer
    extends Composer<_$AppDatabase, $UserActivityTable> {
  $$UserActivityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastChapterRead => $composableBuilder(
    column: $table.lastChapterRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserActivityTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserActivityTable> {
  $$UserActivityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lastChapterRead => $composableBuilder(
    column: $table.lastChapterRead,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserActivityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserActivityTable,
          UserActivityEntity,
          $$UserActivityTableFilterComposer,
          $$UserActivityTableOrderingComposer,
          $$UserActivityTableAnnotationComposer,
          $$UserActivityTableCreateCompanionBuilder,
          $$UserActivityTableUpdateCompanionBuilder,
          (UserActivityEntity, $$UserActivityTableReferences),
          UserActivityEntity,
          PrefetchHooks Function({bool itemId})
        > {
  $$UserActivityTableTableManager(_$AppDatabase db, $UserActivityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserActivityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserActivityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserActivityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int> lastChapterRead = const Value.absent(),
                Value<int> currentPage = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<DateTime> lastReadAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => UserActivityCompanion(
                id: id,
                itemId: itemId,
                lastChapterRead: lastChapterRead,
                currentPage: currentPage,
                progressPercent: progressPercent,
                lastReadAt: lastReadAt,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                Value<int> lastChapterRead = const Value.absent(),
                Value<int> currentPage = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<DateTime> lastReadAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => UserActivityCompanion.insert(
                id: id,
                itemId: itemId,
                lastChapterRead: lastChapterRead,
                currentPage: currentPage,
                progressPercent: progressPercent,
                lastReadAt: lastReadAt,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserActivityTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$UserActivityTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$UserActivityTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserActivityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserActivityTable,
      UserActivityEntity,
      $$UserActivityTableFilterComposer,
      $$UserActivityTableOrderingComposer,
      $$UserActivityTableAnnotationComposer,
      $$UserActivityTableCreateCompanionBuilder,
      $$UserActivityTableUpdateCompanionBuilder,
      (UserActivityEntity, $$UserActivityTableReferences),
      UserActivityEntity,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$SyncLogTableCreateCompanionBuilder =
    SyncLogCompanion Function({
      Value<int> id,
      Value<int?> userId,
      required String entityType,
      required int entityId,
      Value<int?> parentId,
      required String operation,
      required String payload,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });
typedef $$SyncLogTableUpdateCompanionBuilder =
    SyncLogCompanion Function({
      Value<int> id,
      Value<int?> userId,
      Value<String> entityType,
      Value<int> entityId,
      Value<int?> parentId,
      Value<String> operation,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });

class $$SyncLogTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncLogTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncLogTable,
          SyncLogEntry,
          $$SyncLogTableFilterComposer,
          $$SyncLogTableOrderingComposer,
          $$SyncLogTableAnnotationComposer,
          $$SyncLogTableCreateCompanionBuilder,
          $$SyncLogTableUpdateCompanionBuilder,
          (
            SyncLogEntry,
            BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogEntry>,
          ),
          SyncLogEntry,
          PrefetchHooks Function()
        > {
  $$SyncLogTableTableManager(_$AppDatabase db, $SyncLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int> entityId = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncLogCompanion(
                id: id,
                userId: userId,
                entityType: entityType,
                entityId: entityId,
                parentId: parentId,
                operation: operation,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                required String entityType,
                required int entityId,
                Value<int?> parentId = const Value.absent(),
                required String operation,
                required String payload,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncLogCompanion.insert(
                id: id,
                userId: userId,
                entityType: entityType,
                entityId: entityId,
                parentId: parentId,
                operation: operation,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncLogTable,
      SyncLogEntry,
      $$SyncLogTableFilterComposer,
      $$SyncLogTableOrderingComposer,
      $$SyncLogTableAnnotationComposer,
      $$SyncLogTableCreateCompanionBuilder,
      $$SyncLogTableUpdateCompanionBuilder,
      (
        SyncLogEntry,
        BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogEntry>,
      ),
      SyncLogEntry,
      PrefetchHooks Function()
    >;
typedef $$CommentsTableCreateCompanionBuilder =
    CommentsCompanion Function({
      Value<int> id,
      Value<int?> remoteId,
      required int itemId,
      required int userId,
      Value<String> username,
      required String content,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
    });
typedef $$CommentsTableUpdateCompanionBuilder =
    CommentsCompanion Function({
      Value<int> id,
      Value<int?> remoteId,
      Value<int> itemId,
      Value<int> userId,
      Value<String> username,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
    });

class $$CommentsTableFilterComposer
    extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CommentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$CommentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommentsTable,
          CommentEntity,
          $$CommentsTableFilterComposer,
          $$CommentsTableOrderingComposer,
          $$CommentsTableAnnotationComposer,
          $$CommentsTableCreateCompanionBuilder,
          $$CommentsTableUpdateCompanionBuilder,
          (
            CommentEntity,
            BaseReferences<_$AppDatabase, $CommentsTable, CommentEntity>,
          ),
          CommentEntity,
          PrefetchHooks Function()
        > {
  $$CommentsTableTableManager(_$AppDatabase db, $CommentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => CommentsCompanion(
                id: id,
                remoteId: remoteId,
                itemId: itemId,
                userId: userId,
                username: username,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required int itemId,
                required int userId,
                Value<String> username = const Value.absent(),
                required String content,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => CommentsCompanion.insert(
                id: id,
                remoteId: remoteId,
                itemId: itemId,
                userId: userId,
                username: username,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommentsTable,
      CommentEntity,
      $$CommentsTableFilterComposer,
      $$CommentsTableOrderingComposer,
      $$CommentsTableAnnotationComposer,
      $$CommentsTableCreateCompanionBuilder,
      $$CommentsTableUpdateCompanionBuilder,
      (
        CommentEntity,
        BaseReferences<_$AppDatabase, $CommentsTable, CommentEntity>,
      ),
      CommentEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$UserActivityTableTableManager get userActivity =>
      $$UserActivityTableTableManager(_db, _db.userActivity);
  $$SyncLogTableTableManager get syncLog =>
      $$SyncLogTableTableManager(_db, _db.syncLog);
  $$CommentsTableTableManager get comments =>
      $$CommentsTableTableManager(_db, _db.comments);
}
