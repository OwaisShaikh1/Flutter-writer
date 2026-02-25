import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/users_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(AppDatabase db) : super(db);

  // Get user by ID
  Future<UserEntity?> getUserById(int id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Get user by username
  Future<UserEntity?> getUserByUsername(String username) =>
      (select(users)..where((t) => t.username.equals(username))).getSingleOrNull();

  // Watch current user
  Stream<UserEntity?> watchUser(int id) =>
      (select(users)..where((t) => t.id.equals(id))).watchSingleOrNull();

  // Insert or update user
  Future<int> upsertUser(UsersCompanion user) =>
      into(users).insertOnConflictUpdate(user);

  // Update user profile
  Future<void> updateUserProfile({
    required int id,
    String? name,
    String? bio,
    String? email,
  }) {
    return (update(users)..where((t) => t.id.equals(id))).write(UsersCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      bio: bio != null ? Value(bio) : const Value.absent(),
      email: email != null ? Value(email) : const Value.absent(),
    ));
  }

  // Update user stats
  Future<void> updateUserStats({
    required int id,
    int? followers,
    int? following,
    int? posts,
  }) {
    return (update(users)..where((t) => t.id.equals(id))).write(UsersCompanion(
      followers: followers != null ? Value(followers) : const Value.absent(),
      following: following != null ? Value(following) : const Value.absent(),
      posts: posts != null ? Value(posts) : const Value.absent(),
    ));
  }

  // Delete user
  Future<int> deleteUser(int id) =>
      (delete(users)..where((t) => t.id.equals(id))).go();

  // Clear all users (for logout)
  Future<void> clearAllUsers() => delete(users).go();
}
