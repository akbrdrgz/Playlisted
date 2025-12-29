import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';

class UserService {
  UserService(this._db);
  final AppDatabase _db;

  // 1. READ LOGIC - Get all ACTIVE users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final rows = await (_db.select(_db.users)
          ..where((u) => u.isActive.equals(true)))
        .get();

    return rows.map((user) {
      return {
        'id': user.id,
        'username': user.username,
        'isActive': user.isActive,
        'createdAt': user.createdAt.toIso8601String(),
        'updatedAt': user.updatedAt.toIso8601String(),
        'createdBy': user.createdBy,
        'updatedBy': user.updatedBy,
      };
    }).toList();
  }

  // 2. CREATE LOGIC
  Future<void> createUser({
    required String username,
    required String password,
    String createdBy = 'system',
  }) async {
    final now = DateTime.now();

    await _db.into(_db.users).insert(
          UsersCompanion.insert(
            username: username,
            password: password,
            createdAt: now,
            updatedAt: now,
            isActive: const Value(true),
            updatedBy: createdBy,
            createdBy: createdBy,
          ),
        );
  }

  // 3. UPDATE LOGIC
  Future<void> updateUser({
    required int id,
    String? username,
    String? password,
    String updatedBy = 'system',
  }) async {
    final user = await (_db.select(_db.users)
          ..where((u) => (u.id.equals(id)) & (u.isActive.equals(true))))
        .getSingleOrNull();

    if (user == null) {
      throw Exception('Active user ID $id does not exist.');
    }

    final now = DateTime.now();

    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        username: username != null ? Value(username) : const Value.absent(),
        password: password != null ? Value(password) : const Value.absent(),
        updatedAt: Value(now),
        updatedBy: Value(updatedBy),
      ),
    );
  }

  // 4. SOFT DELETE LOGIC
  Future<void> deleteUser(int id, {String deletedBy = 'system'}) async {
    final user = await (_db.select(_db.users)
          ..where((u) => u.id.equals(id) & u.isActive.equals(true)))
        .getSingleOrNull();

    if (user == null) {
      throw Exception('Active user ID $id does not exist.');
    }

    final now = DateTime.now();

    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
        updatedBy: Value(deletedBy),
      ),
    );
  }
}
